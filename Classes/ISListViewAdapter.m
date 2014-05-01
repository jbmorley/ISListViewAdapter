//
// Copyright (c) 2013-2014 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <ISUtilities/ISUtilities.h>
#import "ISListViewAdapter.h"
#import "ISListViewAdapterItem.h"
#import "ISListViewAdapterBlock.h"
#import "ISListViewAdapterItemDescription.h"
#import "ISListViewAdapterSection.h"
#import "ISListViewAdapterArrayOperation.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;


@interface ISListViewAdapter () {
  NSUInteger _version;
}

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) id<ISListViewAdapterDataSource> dataSource;
@property (strong, nonatomic) id<ISListViewAdapterDataSource> pendingDataSource;
@property (nonatomic, strong) NSArray *sections;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic, strong) dispatch_queue_t comparisonQueue;

@end

NSInteger ISDBViewIndexUndefined = -1;

@implementation ISListViewAdapter


+ (id)adapterWithDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  return [[self alloc] initWithDataSource:dataSource];
}


- (id)initWithDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
    self.sections = @[];
    _version = 0;
    
    if ([self.dataSource respondsToSelector:@selector(initializeAdapter:)]) {
      [self.dataSource initializeAdapter:self];
    }
    
    // Create a worker queue on which to perform the
    // item comparison. We may wish to share a global queue
    // across multiple instances by using a default worker.
    NSString *queueIdentifier = [NSString stringWithFormat:@"%@%p",
                                 @"uk.co.inseven.view.",
                                 self];
    self.comparisonQueue
    = dispatch_queue_create([queueIdentifier UTF8String], DISPATCH_QUEUE_SERIAL);
    
    [self updateEntries];
  }
  return self;
}


-(void)log:(NSString *)message, ...
{
  if (self.debug) {
    va_list args;
    va_start(args, message);
    NSLogv(message, args);
    va_end(args);
  }
}


- (void)transitionToDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  self.pendingDataSource = dataSource;
  if ([self.pendingDataSource respondsToSelector:@selector(initializeAdapter:)]) {
    [self.pendingDataSource initializeAdapter:self];
  }
  [self invalidate];
}


- (void)setState:(ISDBViewState)state
{
  @synchronized(self) {
    _state = state;
  }
}


- (void)invalidate
{
  @synchronized (self) {
    self.state = ISDBViewStateInvalid;

    // Only attempt to reload if we have no observers.
    if (self.notifier.count > 0) {
      [self updateEntries];
    }
  }
}


- (void)_runOnMainThread:(void (^)(void))block
{
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_sync(dispatch_get_main_queue(), block);
  }
}


- (ISListViewAdapterItemDescription *)_descriptionForItem:(id)item forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  // TODO Move this elsewhere?
  BOOL dataSourceSupportsSummaries = [dataSource respondsToSelector:@selector(adapter:summaryForItem:)];
  BOOL dataSourceSupportsSections = [dataSource respondsToSelector:@selector(adapter:sectionForItem:)];
  
  __block ISListViewAdapterItemDescription *description =
  [ISListViewAdapterItemDescription new];
  [self _runOnMainThread:^{
    description.identifier =
    [dataSource adapter:self
      identifierForItem:item];
    if (dataSourceSupportsSummaries) {
      description.summary =
      [dataSource adapter:self
           summaryForItem:item];
    }
    if (dataSourceSupportsSections) {
      description.section =
      [dataSource adapter:self
           sectionForItem:item];
    }
  }];
  description.dataSource = dataSource;
  return description;
}


- (NSArray *)_descriptionsForItems:(NSArray *)items forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  NSMutableArray *descriptions =
  [NSMutableArray arrayWithCapacity:items.count];
  for (id item in items) {
    ISListViewAdapterItemDescription *description =
    [self _descriptionForItem:item forDataSource:dataSource];
    [descriptions addObject:description];
  };
  return descriptions;
}


- (NSArray *)_sectionsForItems:(NSArray *)items forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  BOOL dataSourceSupportsSections = [dataSource respondsToSelector:@selector(adapter:sectionForItem:)];
  
  // Conver the items to descriptions.
  NSArray *descriptions =
  [self _descriptionsForItems:items forDataSource:dataSource];
  
  // Build the section structure.
  NSMutableDictionary *sectionLookup =
  [NSMutableDictionary dictionaryWithCapacity:3];
  NSMutableArray *sections =
  [NSMutableArray arrayWithCapacity:3];
  if (dataSourceSupportsSections) {
    
    for (ISListViewAdapterItemDescription *description in
         descriptions) {
      
      // Find the section, creating one if required.
      ISListViewAdapterSection *section =
      sectionLookup[description.section];
      if (section == nil) {
        section = [ISListViewAdapterSection new];
        section.title = description.section;
        sectionLookup[description.section] = section;
        [sections addObject:section];
      }
      
      // Add the item to the section.
      [section.items addObject:description];
      
    }
    
  } else {
    
    if (descriptions.count > 0) {
      ISListViewAdapterSection *section = [ISListViewAdapterSection new];
      section.title = @"";
      section.items = [descriptions mutableCopy];
      [sections addObject:section];
    }
  }

  return sections;
}


- (NSArray *)_changesFromArray:(NSArray *)before
                       toArray:(NSArray *)after
                        result:(NSArray **)result
{
  NSMutableArray *changes = [NSMutableArray arrayWithCapacity:3];
  
  NSMutableArray *beforeUpToDate = [before mutableCopy];
  NSMutableIndexSet *sectionRemovals =
  [NSMutableIndexSet indexSet];
  
  [self log:@"From Array: %@", before];
  [self log:@"To Array: %@", after];
  
  // Process removes.
  for (NSInteger i = 0; i < beforeUpToDate.count; i++) {
    id itemBefore = before[i];
    NSInteger idxBefore = i;
    NSInteger idxAfter =
    [after indexOfObject:itemBefore];
    
    // If the item doesn't exist in the new world, remove it.
    if (idxAfter == NSNotFound) {
      [changes addObject:[ISListViewAdapterArrayOperation delete:idxBefore]];
      [sectionRemovals addIndex:idxBefore];
    }
    
  }
  
  // Process item moves (ignoring insertions)
  [beforeUpToDate removeObjectsAtIndexes:sectionRemovals];
  NSInteger l = 0;
  NSInteger r = 0;
  while (l < after.count) {

    // Terminate when we have got to the end of beforeUpToDate.
    // The remaining items must be new.
    if (r >= beforeUpToDate.count) {
      break;
    }
    
    id itemBefore = beforeUpToDate[r];
    id itemAfter = after[l];
    
    if ([itemBefore isEqual:itemAfter]) {
      
      l++; r++;
      continue;
      
    } else if (![itemBefore isEqual:itemAfter]) {
      
      // Look for an item to move into place.
      NSInteger move = [beforeUpToDate indexOfObject:itemAfter];
      
      // If we've found an object to move then do so.
      // Note that we still use the _old_ initial indexes
      // when moving items.
      if (move != NSNotFound) {
        NSInteger originalIndex =
        [before indexOfObject:itemAfter];
        [changes addObject:[ISListViewAdapterArrayOperation move:originalIndex to:l]];
        
        ISListViewAdapterSection *section =
        [beforeUpToDate objectAtIndex:move];
        [beforeUpToDate removeObjectAtIndex:move];
        [beforeUpToDate insertObject:section
                             atIndex:r];
        
        l++; r++;
        continue;
        
      } else {
        
        // If the item is new, we step l knowing it will be
        // inserted for us later.
        l++;
        continue;
        
      }
      
    }
    
  }
  
  // Process insertions.
  for (NSInteger i = 0; i < after.count; i++) {
    id itemAfter = after[i];
    NSInteger idxAfter = i;
    NSInteger idxBefore =
    [beforeUpToDate indexOfObject:itemAfter];
    
    // If the item doesn't exist in the old world, add it.
    if (idxBefore == NSNotFound) {
      [changes addObject:[ISListViewAdapterArrayOperation insert:idxAfter]];
      [beforeUpToDate insertObject:itemAfter
                           atIndex:idxAfter];
    }
  }
  
  // Create the new array.
  NSMutableArray *res =
  [NSMutableArray arrayWithCapacity:after.count];
  for (id item in after) {
    NSInteger index = [before indexOfObject:item];
    id newItem = nil;
    if (index == NSNotFound) {
      newItem = item;
    } else {
      newItem = [before objectAtIndex:index];
    }
    [res addObject:newItem];
  }
  *result = res;
  
  return changes;
}


- (ISListViewAdapterChanges *)_changesBetweenArray:(NSArray *)before andArray:(NSArray *)after
{
  ISListViewAdapterChanges *changes =
  [[ISListViewAdapterChanges alloc] initWithLogger:self];
  
  [self log:@"From:\n%@", before];
  [self log:@"To:\n%@", after];
  
  // Track removals internally to allow us to process moves
  // more effectively.
  NSMutableArray *beforeUpToDate = [before mutableCopy];
  NSMutableIndexSet *sectionRemovals =
  [NSMutableIndexSet indexSet];
  
  // Process section removes.
  for (NSInteger i = 0; i < beforeUpToDate.count; i++) {
    ISListViewAdapterSection *sectionBefore = beforeUpToDate[i];
    NSInteger sectionIdxBefore = i;
    NSInteger sectionIdxAfter =
    [after indexOfObject:sectionBefore];
    
    // If the section doesn't exist in the new world, remove it.
    if (sectionIdxAfter == NSNotFound) {
      [changes deleteSection:sectionIdxBefore];
      [sectionRemovals addIndex:sectionIdxBefore];
    }
    
  }
  
  // Process section moves (ignoring insertions)
  [beforeUpToDate removeObjectsAtIndexes:sectionRemovals];
  NSInteger l = 0;
  NSInteger r = 0;
  while (l < after.count) {
    [self log:@"Checking Sections: %lu", l];
    
    // Terminate when we have got to the end of beforeUpToDate.
    // The remaining items must be new.
    if (r >= beforeUpToDate.count) {
      break;
    }
    
    ISListViewAdapterSection *sectionBefore = beforeUpToDate[r];
    ISListViewAdapterSection *sectionAfter = after[l];

    if ([sectionBefore isEqual:sectionAfter]) {
      
      l++; r++;
      continue;
      
    } else if (![sectionBefore isEqual:sectionAfter]) {
      
      // Look for an item to move into place.
      NSInteger move = [beforeUpToDate indexOfObject:sectionAfter];

      // If we've found an object to move then do so.
      // Note that we still use the _old_ initial indexes
      // when moving items.
      if (move != NSNotFound) {
        NSInteger originalIndex = [before indexOfObject:sectionAfter];
        [changes moveSection:originalIndex
                   toSection:l];
        
        ISListViewAdapterSection *section =
        [beforeUpToDate objectAtIndex:move];
        [beforeUpToDate removeObjectAtIndex:move];
        [beforeUpToDate insertObject:section
                             atIndex:r];
        
        l++; r++;
        continue;

      } else {
        
        // If the item is new, we step l knowing it will be
        // inserted for us later.
        l++;
        continue;
        
      }
      
    }
    
  }
  
  
  // Process section insertions.
  for (NSInteger i = 0; i < after.count; i++) {
    ISListViewAdapterSection *sectionAfter = after[i];
    NSInteger sectionIdxAfter = i;
    NSInteger sectionIdxBefore =
    [beforeUpToDate indexOfObject:sectionAfter];
    
    // If the section doesn't exist in the old world, add it.
    if (sectionIdxBefore == NSNotFound) {
      [changes insertSection:sectionIdxAfter];
      [beforeUpToDate insertObject:sectionAfter
                           atIndex:sectionIdxAfter];
    }
  }
  
  // Iterate over the items in the sections.
  for (ISListViewAdapterSection *sectionAfter in after) {
    NSInteger sectionIdxBefore = [before indexOfObject:sectionAfter];
    NSInteger sectionIdxAfter = [after indexOfObject:sectionAfter];
    
    if (sectionIdxBefore != NSNotFound) {
    
      ISListViewAdapterSection *sectionBefore = before[sectionIdxBefore];
      
      NSArray *beforeItems = sectionBefore.items;
      NSArray *afterItems = sectionAfter.items;
      
      // Track removals internally to allow us to process moves
      // more effectively.
      NSMutableArray *beforeItemsUpToDate =
      [beforeItems mutableCopy];
      NSMutableIndexSet *itemRemovals =
      [NSMutableIndexSet indexSet];
      
      // Process item removes.
      for (NSInteger i = 0; i < beforeItemsUpToDate.count; i++) {
        ISListViewAdapterItemDescription *itemBefore = beforeItemsUpToDate[i];
        NSInteger itemIdxBefore = i;
        NSInteger itemIdxAfter =
        [afterItems indexOfObject:itemBefore];
        
        // If the item doesn't exist in the new world, remove it.
        if (itemIdxAfter == NSNotFound) {
          [changes deleteItem:itemIdxBefore
                    inSection:sectionIdxBefore];
          [itemRemovals addIndex:itemIdxBefore];
        }
        
      }
      
      // Process item moves (ignoring insertions)
      [beforeItemsUpToDate removeObjectsAtIndexes:itemRemovals];
      NSInteger l = 0;
      NSInteger r = 0;
      while (l < afterItems.count) {
        
        // Terminate when we have got to the end of beforeUpToDate.
        // The remaining items must be new.
        if (r >= beforeItemsUpToDate.count) {
          break;
        }
        
        ISListViewAdapterItemDescription *itemBefore = beforeItemsUpToDate[r];
        ISListViewAdapterItemDescription *itemAfter = afterItems[l];
        
        if ([itemBefore isEqual:itemAfter]) {
          
          l++; r++;
          continue;
          
        } else if (![itemBefore isEqual:itemAfter]) {
          
          // Look for an item to move into place.
          NSInteger move = [beforeItemsUpToDate indexOfObject:itemAfter];
          
          // If we've found an object to move then do so.
          // Note that we still use the _old_ initial indexes
          // when moving items.
          if (move != NSNotFound) {
            NSInteger originalIndex = [beforeItems indexOfObject:itemAfter];
            [changes moveItem:originalIndex
                    inSection:sectionIdxBefore
                       toItem:l
                    inSection:sectionIdxAfter];
            
            ISListViewAdapterItemDescription *item =
            [beforeItemsUpToDate objectAtIndex:move];
            [beforeItemsUpToDate removeObjectAtIndex:move];
            [beforeItemsUpToDate insertObject:item
                                      atIndex:r];
            
            // It's safe to increment the left and right counts
            // as we've placed everything in order.
            l++; r++;
            continue;
            
          } else {
            
            // If the item is new, we step l knowing it will be
            // inserted for us later.
            l++;
            continue;
            
          }
          
        }
        
      }
      
      
      // Process item insertions.
      for (NSInteger i = 0; i < afterItems.count; i++) {
        ISListViewAdapterItemDescription *itemAfter = afterItems[i];
        NSInteger itemIdxAfter = i;
        NSInteger itemIdxBefore =
        [beforeItemsUpToDate indexOfObject:itemAfter];
        
        // If the section doesn't exist in the old world, add it.
        if (itemIdxBefore == NSNotFound) {
          [changes insertItem:itemIdxAfter
                    inSection:sectionIdxAfter];
          [beforeItemsUpToDate insertObject:itemAfter
                                    atIndex:itemIdxAfter];
        }
      }
      
    }
    
  }
  
  return changes;
}


- (void)updateEntries
{
  [self log:@"updateEntries"];
  
  // Perform the update and comparison on a different thread
  // to ensure we do not block the UI thread.  Since we are
  // always dispatching updates onto a common queue we can
  // guarantee that updates are performed in order (though
  // they may be delayed).
  // Updates are cross-posted back to the main thread.
  // We are using an ordered dispatch queue here, so it is
  // guaranteed that the current entries will not be being
  // edited a this point.
  // As we are only performing a read, we can safely do so
  // without entering a synchronized block.
  dispatch_async(self.comparisonQueue, ^{
    
    // Only run if we believe the state is invalid.
    // TODO This is not good enough.
    @synchronized (self) {
      if (self.state == ISDBViewStateValid) {
        return;
      }
    }
    
    // Get our desired data source.
    __block id<ISListViewAdapterDataSource> dataSource;
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (self.pendingDataSource) {
        dataSource = self.pendingDataSource;
        self.pendingDataSource = nil;
      } else {
        dataSource = self.dataSource;
      }
    });
    
    // Fetch the current state.
    __block NSMutableArray *sections;
    __block NSMutableArray *completionEntries;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_main_queue(), ^{
      sections = [self.sections copy];
      [dataSource itemsForAdapter:self
       completionBlock:^(NSArray *entries) {
         completionEntries = [entries mutableCopy];
         self.state = ISDBViewStateValid;
         dispatch_semaphore_signal(sema);
       }];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Generate descriptions for the items.
    NSArray *updatedSections =
    [self _sectionsForItems:completionEntries forDataSource:dataSource];
    
    // First, apply the section changes.
    NSArray *result;
    NSArray *changes =
    [self _changesFromArray:sections
                    toArray:updatedSections
                     result:&result];
    ISListViewAdapterChanges *sectionChanges =
    [ISListViewAdapterChanges changesWithLogger:self];
    for (ISListViewAdapterArrayOperation *operation in changes) {
      if (operation.type ==
          ISListViewAdapterArrayOperationTypeInsert) {
        [sectionChanges insertSection:operation.index];
      } else if (operation.type ==
                 ISListViewAdapterArrayOperationTypeDelete) {
        [sectionChanges deleteSection:operation.index];
      } else if (operation.type ==
                 ISListViewAdapterArrayOperationTypeMove) {
        [sectionChanges moveSection:operation.index
                          toSection:operation.toIndex];
      }
    }
    [self log:@"Applying section changes..."];
    [self _applyChanges:sectionChanges
               forState:result
             dataSource:dataSource];
    
    // Second, item changes.
    
    // Calculate item the changes.
    // TODO We should mark the sections which haven't
    // changed so we don't bother updating these.
    ISListViewAdapterChanges *itemChanges =
    [ISListViewAdapterChanges changesWithLogger:self];
    for (int i=0; i<updatedSections.count; i++) {
      ISListViewAdapterSection *sectionAfter = updatedSections[i];
      NSInteger indexBefore = [sections indexOfObject:sectionAfter];
      if (indexBefore == NSNotFound) {
        continue;
      }
      ISListViewAdapterSection *sectionBefore = sections[indexBefore];
      
      NSArray *newItems = nil;
      NSArray *changes =
      [self _changesFromArray:sectionBefore.items
                      toArray:sectionAfter.items
                       result:&newItems];
      sectionAfter.items = [newItems mutableCopy];
      
      // Iterate over the changes and apply them to a change set.
      for (ISListViewAdapterArrayOperation *operation in changes) {
        if (operation.type ==
            ISListViewAdapterArrayOperationTypeInsert) {
          [itemChanges insertItem:operation.index
                        inSection:i];
        } else if (operation.type ==
                   ISListViewAdapterArrayOperationTypeDelete) {
          [itemChanges deleteItem:operation.index
                        inSection:i];
        } else if (operation.type ==
                   ISListViewAdapterArrayOperationTypeMove) {
          [itemChanges moveItem:operation.index
                      inSection:i
                         toItem:operation.toIndex
                      inSection:i];
        }
      }
    }
    
    // Apply the item changes.
    [self log:@"Applying item changes..."];
    [self _applyChanges:itemChanges
               forState:updatedSections
             dataSource:dataSource];
    
    
    // Determine the changes to the sections.
//    ISListViewAdapterChanges *changes = [self _changesBetweenArray:sections andArray:updatedSections];

//    [self _applyChanges:changes
//               forState:updatedSections
//             dataSource:dataSource];
    
  });
  
}


- (void)_applyChanges:(ISListViewAdapterChanges *)changes
             forState:(NSArray *)state
           dataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  [self log:@"Changes: %@", changes];
  [self log:@"State: %@", state];
  
  // Update the state and notify our observers.
  dispatch_sync(dispatch_get_main_queue(), ^{
    
    // Increment the version seen.
    NSUInteger previousVersion = _version;
    _version = _version + 1;
    
    // Update the internal state.
    self.dataSource = dataSource;
    self.sections = state;
    
    // Notify the observers of the additions, removals, moves.
    if (![changes empty]) {
      [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
                 withObject:self
                 withObject:changes
                 withObject:@(previousVersion)];
    }
    
  });
}


- (NSUInteger)numberOfSections
{
  return self.sections.count;
}


- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
  [self updateEntries];
  ISListViewAdapterSection *s = self.sections[section];
  return s.items.count;
}


- (NSUInteger)version
{
  return _version;
}


- (ISListViewAdapterItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
  // Check that we're asking for a valid index.
  // Sometimes it seems possible that UICollectionView and friends
  // will ask us for a cell we've already told it is disappearing.
  if ((indexPath.section >= self.sections.count) || (indexPath.row >= [self.sections[indexPath.section] items].count)) {
    return nil;
  }
  
  ISListViewAdapterSection *s =
  self.sections[indexPath.section];
  ISListViewAdapterItemDescription *description =
  s.items[indexPath.item];
  ISListViewAdapterItem *item =
  [ISListViewAdapterItem itemWithAdapter:self
                              dataSource:description.dataSource
                              identifier:description.identifier];
  return item;
}


- (NSString *)titleForSection:(NSInteger)section
{
  ISListViewAdapterSection *s = self.sections[section];
  return s.title;
}


#pragma mark - Observers


- (void)addAdapterObserver:(id<ISListViewAdapterObserver>)observer
{
  [self.notifier addObserver:observer];
}


- (void)removeObserver:(id<ISListViewAdapterObserver>)observer
{
  [self.notifier removeObserver:observer];
}


@end
