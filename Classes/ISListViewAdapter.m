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
#import "ISListViewAdapterBlock.h"
#import "ISListViewAdapterItemDescription.h"
#import "ISListViewAdapterSection.h"
#import "ISListViewAdapterArrayOperation.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;

NSString *const ISListViewAdapterInvalidSection = @"ISListViewAdapterInvalidSection";


@interface ISListViewAdapter ()

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
    self.state = ISDBViewStateValid;
    self.notifier = [ISNotifier new];
    self.sections = @[];
    
    if ([self.dataSource respondsToSelector:@selector(adapter:initialize:)]) {
      [self.dataSource adapter:self initialize:[ISListViewAdapterInvalidator invalidatorWithAdapter:self]];
    }
    
    // Create a worker queue on which to perform the
    // item comparison. We may wish to share a global queue
    // across multiple instances by using a default worker.
    NSString *queueIdentifier = [NSString stringWithFormat:@"%@%p",
                                 @"uk.co.inseven.view.",
                                 self];
    self.comparisonQueue
    = dispatch_queue_create([queueIdentifier UTF8String], DISPATCH_QUEUE_SERIAL);
    
    [self invalidate];
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
  if ([self.pendingDataSource respondsToSelector:@selector(adapter:initialize:)]) {
    [self.pendingDataSource adapter:self initialize:[ISListViewAdapterInvalidator invalidatorWithAdapter:self]];
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
    
    // Don't attempt to perform another update if we're
    // already marked as invalid.
    if (self.state == ISDBViewStateInvalid) {
      return;
    }
    
    self.state = ISDBViewStateInvalid;
    [self updateEntries];
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


- (ISListViewAdapterItemDescription *)_descriptionForIdentifier:(id)identifier forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  BOOL dataSourceSupportsSummaries = [dataSource respondsToSelector:@selector(adapter:summaryForIdentifier:)];
  BOOL dataSourceSupportsSections = [dataSource respondsToSelector:@selector(adapter:sectionForIdentifier:)];
  
  __block ISListViewAdapterItemDescription *description =
  [ISListViewAdapterItemDescription new];
  [self _runOnMainThread:^{
    description.identifier = identifier;
    if (dataSourceSupportsSummaries) {
      description.summary =
      [dataSource adapter:self
     summaryForIdentifier:identifier];
    }
    if (dataSourceSupportsSections) {
      description.section =
      [dataSource adapter:self
     sectionForIdentifier:identifier];
      if (description.section == nil) {
        @throw [NSException exceptionWithName:ISListViewAdapterInvalidSection reason:@"Sections must not be nil." userInfo:nil];
      }
      assert(description.section != nil);
    }
  }];
  description.dataSource = dataSource;
  return description;
}


- (NSArray *)_descriptionsForIdentifiers:(NSArray *)identifiers forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  NSMutableArray *descriptions =
  [NSMutableArray arrayWithCapacity:identifiers.count];
  for (id identifier in identifiers) {
    ISListViewAdapterItemDescription *description =
    [self _descriptionForIdentifier:identifier forDataSource:dataSource];
    [descriptions addObject:description];
  };
  return descriptions;
}


- (NSArray *)_sectionsForIdentifiers:(NSArray *)identifiers forDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  BOOL dataSourceSupportsSections = [dataSource respondsToSelector:@selector(adapter:sectionForIdentifier:)];
  
  // Conver the items to descriptions.
  NSArray *descriptions =
  [self _descriptionsForIdentifiers:identifiers forDataSource:dataSource];
  
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
      [dataSource
       identifiersForAdapter:self
       completionBlock:^(NSArray *entries) {
         completionEntries = [entries mutableCopy];
         self.state = ISDBViewStateValid;
         dispatch_semaphore_signal(sema);
       }];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Generate descriptions for the items.
    NSArray *updatedSections =
    [self _sectionsForIdentifiers:completionEntries forDataSource:dataSource];
    
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
    ISListViewAdapterChanges *itemChanges =
    [ISListViewAdapterChanges changesWithLogger:self];
    ISListViewAdapterChanges *itemUpdates =
    [ISListViewAdapterChanges changesWithLogger:self];
    for (int i=0; i<updatedSections.count; i++) {
      ISListViewAdapterSection *sectionAfter = updatedSections[i];
      NSInteger indexBefore = [sections indexOfObject:sectionAfter];
      if (indexBefore == NSNotFound) {
        continue;
      }
      ISListViewAdapterSection *sectionBefore = sections[indexBefore];
      
      // Enumerate the updates.
      for (NSInteger idxAfter = 0;
           idxAfter < sectionAfter.items.count;
           idxAfter++) {
        ISListViewAdapterItemDescription *itemAfter =
        sectionAfter.items[idxAfter];
        NSInteger idxBefore =
        [sectionBefore.items indexOfObject:itemAfter];
        if (idxBefore != NSNotFound) {
          ISListViewAdapterItemDescription *itemBefore = sectionBefore.items[idxBefore];
          if (![itemBefore isSummaryEqual:itemAfter]) {
            [itemUpdates updateItem:idxAfter inSection:i];
          }
        }
      }
      
      // Enumerate the inserts, deletes and moves.
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
    
    // Apply the item updates.
    [self log:@"Applying item updates..."];
    [self _applyChanges:itemUpdates
               forState:updatedSections
             dataSource:dataSource];
    
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
    
    // Update the internal state.
    self.dataSource = dataSource;
    self.sections = state;
    
    // Notify the observers of the additions, removals, moves.
    if (![changes empty]) {
      [self.notifier notify:@selector(adapter:performBatchUpdates:)
                 withObject:self
                 withObject:changes];
    }
    
  });
}


- (NSUInteger)numberOfSections
{
  return self.sections.count;
}


- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
  ISListViewAdapterSection *s = self.sections[section];
  return s.items.count;
}


- (void)_dispatchToMainThread:(void (^)(void))block
{
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}


- (void)itemForIndexPath:(NSIndexPath *)indexPath
         completionBlock:(ISListViewAdapterBlock)completionBlock
{
  // Check that we're asking for a valid index.
  // Sometimes it seems possible that UICollectionView and friends
  // will ask us for a cell we've already told it is disappearing.
  if ((indexPath.section >= self.sections.count) || (indexPath.row >= [self.sections[indexPath.section] items].count)) {
    [self _dispatchToMainThread:^{
      completionBlock(nil);
    }];
  }
  
  ISListViewAdapterSection *s =
  self.sections[indexPath.section];
  ISListViewAdapterItemDescription *description =
  s.items[indexPath.item];
  
  [self _dispatchToMainThread:^{
    [self.dataSource adapter:self
           itemForIdentifier:description.identifier
             completionBlock:^(id item) {
               [self _dispatchToMainThread:^{
                 completionBlock(item);
               }];
             }];
  }];
}


- (id)itemForIndexPath:(NSIndexPath *)indexPath
{
  __block id result = nil;
  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
  [self itemForIndexPath:indexPath completionBlock:^(id item) {
    result = item;
    dispatch_semaphore_signal(sema);
  }];
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  return result;
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
