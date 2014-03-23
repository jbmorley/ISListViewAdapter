//
// Copyright (c) 2013 InSeven Limited.
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
@property (nonatomic) dispatch_queue_t comparisonQueue;

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


- (void)transitionToDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  self.pendingDataSource = dataSource;
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
    ISListViewAdapterSection *section = [ISListViewAdapterSection new];
    section.items = [descriptions mutableCopy];
    [sections addObject:section];
  }

  return sections;
}


- (ISListViewAdapterChanges *)_changesBetweenArray:(NSArray *)before andArray:(NSArray *)after
{
  ISListViewAdapterChanges *changes =
  [ISListViewAdapterChanges new];
  
  NSLog(@"From:\n%@", before);
  NSLog(@"To:\n%@", after);
  
  
  
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
  
  // Process section insertions.
  [beforeUpToDate removeObjectsAtIndexes:sectionRemovals];
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
  
  // Process section moves.
  for (NSInteger i = 0; i < before.count; i++) {
    ISListViewAdapterSection *sectionBefore = before[i];
    NSInteger sectionIdxBefore = i;
    NSInteger sectionIdxAfter =
    [after indexOfObject:sectionBefore];
    
    // If the section doesn't exist in the new world, remove it.
    if (sectionIdxAfter != NSNotFound &&
        sectionIdxAfter != sectionIdxBefore) {
      [changes moveSection:sectionIdxBefore
                 toSection:sectionIdxAfter];
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
      for (NSInteger i = 0; i < beforeItems.count; i++) {
        ISListViewAdapterItemDescription *itemBefore = beforeItems[i];
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
      
      // Process item insertions.
      [beforeItemsUpToDate removeObjectsAtIndexes:itemRemovals];
      for (NSInteger i = 0; i < afterItems.count; i++) {
        ISListViewAdapterItemDescription *itemAfter = afterItems[i];
        NSInteger itemIdxAfter = i;
        NSInteger itemIdxBefore =
        [beforeItemsUpToDate indexOfObject:itemAfter];
        
        // If the section doesn't exist in the old world, add it.
        if (itemIdxBefore == NSNotFound) {
//          [changes insertItem:itemIdxAfter
//                    inSection:sectionIdxAfter];
//          [changes insertItem:itemIdxAfter
//                    inSection:sectionIdxBefore];
          [changes insertItem:itemIdxAfter
                    inSection:sectionIdxAfter];
          [beforeItemsUpToDate insertObject:itemAfter
                                    atIndex:itemIdxAfter];
//          [beforeItemsUpToDate insertObject:itemAfter
//                                    atIndex:itemIdxBefore];
        }
      }
      
      // Process item moves.
      for (NSInteger i = 0; i < beforeItems.count; i++) {
        ISListViewAdapterItemDescription *itemBefore = beforeItems[i];
        NSInteger itemIdxBefore = i;
        NSInteger itemIdxAfter =
        [afterItems indexOfObject:itemBefore];
        
        // If the section doesn't exist in the new world, remove it.
        if (itemIdxAfter != NSNotFound &&
            itemIdxAfter != itemIdxBefore) {
          [changes moveItem:itemIdxBefore
                  inSection:sectionIdxBefore
                     toItem:itemIdxAfter
                  inSection:sectionIdxAfter];
//          [changes moveItem:itemIdxBefore
//                  inSection:sectionIdxBefore
//                     toItem:itemIdxAfter
//                  inSection:sectionIdxBefore];
        }
      }

    }
    
  }
  
  
  
//  
//  
//  
//  // Removes and moves.
//  for (NSInteger i = before.count-1; i >= 0; i--) {
//    ISListViewAdapterSection *section = before[i];
//    NSUInteger newSectionIndex = [after indexOfObject:section];
//    
//    // If the section is present before and after the update
//    // then we need to determine the changes to its items.
//    if (newSectionIndex != NSNotFound) {
//      NSArray *itemsBefore = section.items;
//      NSArray *itemsAfter = [[after objectAtIndex:newSectionIndex] items];
//      
//      // Item removes and moves.
//      for (NSInteger j = itemsBefore.count-1; j >= 0; j--) {
//        ISListViewAdapterItemDescription *item = itemsBefore[j];
//        
//        // Determine the type of operation.
//        NSUInteger newItemIndex =
//        [itemsAfter indexOfObject:item];
//        if (newItemIndex == NSNotFound) { // Item delete.
//          [changes deleteItem:j
//                    inSection:i];
//        } else if (j != newItemIndex) { // Item move.
//          [changes moveItem:j
//                  inSection:i
//                     toItem:newItemIndex
//                  inSection:i];
//        }
//        
//      }
//      
//    }
//    
//    // Determine the type of the operation.
//    if (newSectionIndex == NSNotFound) { // Delete.
//      [changes deleteSection:i];
//    } else if (i != newSectionIndex) { // Move.
////      [changes moveSection:i toSection:newSectionIndex];
//    }
//    
//    if (newSectionIndex != NSNotFound) {
//      NSArray *itemsBefore = section.items;
//      NSArray *itemsAfter = [[after objectAtIndex:newSectionIndex] items];
//      
//      // Item insertions.
//      for (NSUInteger j = 0; j < itemsAfter.count; j++) {
//        ISListViewAdapterItemDescription *item = itemsAfter[j];
//        
//        // Determine the type of operation.
//        NSUInteger oldItemIndex =
//        [itemsBefore indexOfObject:item];
//        if (oldItemIndex == NSNotFound) { // Insert.
//          [changes insertItem:j
//                    inSection:i];
//        } else {
//          
//          //          // Check for updates.
//          //          // We only do this if the objects we're comparing implement
//          //          // the isSummaryEqual: selector.
//          //          id oldEntry = [before objectAtIndex:oldIndex];
//          //          if ([oldEntry respondsToSelector:@selector(isSummaryEqual:)]) {
//          //            if (![oldEntry isSummaryEqual:section]) {
//          //
//          //              // Update.
//          //              // TODO (index i)
//          //
//          //            }
//        }
//        
//      }
//      
//    }
//    
//    
//  }
//  
//  // Additions and updates.
//  for (NSUInteger i = 0; i < after.count; i++) {
//    ISListViewAdapterSection *section = after[i];
//    
//    // Determine the type of operation.
//    NSUInteger oldIndex = [before indexOfObject:section];
//    if (oldIndex == NSNotFound) { // Insert.
//      [changes insertSection:i];
//    }
//    
//  }
  
  return changes;
}


- (void)updateEntries
{
  
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
    
    // Determine the changes to the sections.
    ISListViewAdapterChanges *changes = [self _changesBetweenArray:sections andArray:updatedSections];
    
    // Update the state and notify our observers.
    dispatch_sync(dispatch_get_main_queue(), ^{
      
      // Increment the version seen.
      NSUInteger previousVersion = _version;
      _version = _version + 1;
      
      // Update the internal state.
      self.dataSource = dataSource;
      self.sections = updatedSections;
      
      // Notify the observers of the additions, removals, moves.
      // TODO Guard against no changes.
      [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:) withObject:self withObject:changes withObject:@(previousVersion)];
      
//      // TODO Consider whether this is sensible.
//      // Notify the observers of updates in a separate block to
//      // avoid performing multiple operations to individual
//      // items (it seems to break UITableView).
//      if (sectionUpdates.count > 0) {
//        [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
//                   withObject:self
//                   withObject:sectionUpdates
//                   withObject:@(previousVersion)];
//      }
      
//      // TODO Dummy udpate. Remove.
//      [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
//                 withObject:self
//                 withObject:@[]
//                 withObject:@(previousVersion)];
      
    });

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


- (ISListViewAdapterItem *)itemForIdentifier:(id)identifier
{
  ISListViewAdapterItem *item = [ISListViewAdapterItem itemWithAdapter:self identifier:identifier];
  return item;
}


- (ISListViewAdapterItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
  ISListViewAdapterSection *s =
  self.sections[indexPath.section];
  ISListViewAdapterItemDescription *description =
  s.items[indexPath.item];
  ISListViewAdapterItem *item = [ISListViewAdapterItem itemWithAdapter:self identifier:description.identifier];
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
