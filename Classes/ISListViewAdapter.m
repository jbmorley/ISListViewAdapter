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

#import "ISListViewAdapter.h"
#import "ISNotifier.h"
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
@property (nonatomic, strong) NSArray *sections;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic) dispatch_queue_t comparisonQueue;
@property (nonatomic, assign) BOOL dataSourceSupportsSummaries;
@property (nonatomic, assign) BOOL dataSourceSupportsSections;

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
    self.entries = @[];
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
    
    // Check what the data source supports.
    self.dataSourceSupportsSummaries = [self.dataSource respondsToSelector:@selector(adapter:summaryForItem:)];
    self.dataSourceSupportsSections = [self.dataSource respondsToSelector:@selector(adapter:sectionForItem:)];
    
    [self updateEntries];
  }
  return self;
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


- (ISListViewAdapterItemDescription *)_descriptionForItem:(id)item
{
  __block ISListViewAdapterItemDescription *description =
  [ISListViewAdapterItemDescription new];
  [self _runOnMainThread:^{
    description.identifier =
    [self.dataSource adapter:self
           identifierForItem:item];
    if (self.dataSourceSupportsSummaries) {
      description.summary =
      [self.dataSource adapter:self
                summaryForItem:item];
    }
    if (self.dataSourceSupportsSections) {
      description.section =
      [self.dataSource adapter:self
                sectionForItem:item];
    }
  }];
  return description;
}


- (NSArray *)_descriptionsForItems:(NSArray *)items
{
  NSMutableArray *descriptions =
  [NSMutableArray arrayWithCapacity:items.count];
  for (id item in items) {
    ISListViewAdapterItemDescription *description =
    [self _descriptionForItem:item];
    [descriptions addObject:description];
  };
  return descriptions;
}


- (NSArray *)_sectionsForItems:(NSArray *)items
{
  // Conver the items to descriptions.
  NSArray *descriptions =
  [self _descriptionsForItems:items];
  
  // Build the section structure.
  NSMutableDictionary *sectionLookup =
  [NSMutableDictionary dictionaryWithCapacity:3];
  NSMutableArray *sections =
  [NSMutableArray arrayWithCapacity:3];
  if (self.dataSourceSupportsSections) {
    
    for (ISListViewAdapterItemDescription *description in
         descriptions) {
      
      // Find the section, creating one if required.
      ISListViewAdapterSection *section =
      sectionLookup[description.section];
      if (section == nil) {
        section = [ISListViewAdapterSection new];
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


- (NSArray *)_changesBetweenArray:(NSArray *)before
                         andArray:(NSArray *)after
{
  NSMutableArray *actions =
  [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *updates =
  [NSMutableArray arrayWithCapacity:3];
  NSInteger countBefore = before.count;
  NSInteger countAfter = after.count;
  
  NSInteger additionCount = 0;
  NSInteger removalCount = 0;
  NSInteger updateCount = 0;
  NSInteger moveCount = 0;
  
  // Removes and moves.
  for (NSInteger i = before.count-1; i >= 0; i--) {
    id entry = [before objectAtIndex:i];
    
    // Determine the type of the operation.
    NSUInteger newIndex =
    [after indexOfObject:entry];
    if (newIndex == NSNotFound) {
      
      // Create an operation.
      ISListViewAdapterOperation *operation =
      [ISListViewAdapterOperation new];
      
      // Remove.
      operation.type =
      ISListViewAdapterOperationTypeDelete;
      operation.previousIndex =
      [NSIndexPath indexPathForItem:i
                          inSection:0];
      [actions addObject:operation];
      
      // Track the removal.
      removalCount++;
      countBefore--;
      
    } else if (i != newIndex) {
      
      // Create an operation.
      ISListViewAdapterOperation *operation =
      [ISListViewAdapterOperation new];
      
      // Move.
      operation.type =
      ISListViewAdapterOperationTypeMove;
      operation.previousIndex =
      [NSIndexPath indexPathForItem:i
                          inSection:0];
      operation.currentIndex =
      [NSIndexPath indexPathForItem:newIndex
                          inSection:0];
      [actions addObject:operation];
      
      // Track the move.
      moveCount++;
      
    }
  }
  
  // Additions and updates.
  for (NSUInteger i = 0; i < after.count; i++) {
    id entry = [after objectAtIndex:i];
    
    // Determine the index of the operation.
    NSUInteger oldIndex =
    [before indexOfObject:entry];
    
    if (oldIndex == NSNotFound) {
      
      // Create an operation.
      ISListViewAdapterOperation *operation =
      [ISListViewAdapterOperation new];
      
      // Add.
      operation.type =
      ISListViewAdapterOperationTypeInsert;
      operation.currentIndex =
      [NSIndexPath indexPathForItem:i
                          inSection:0];
      [actions addObject:operation];
      
      // Track the addition.
      countBefore++;
      additionCount++;
      
    } else {
      
      // Check for updates.
      // We only do this if the objects we're comparing implement
      // the isSummaryEqual: selector.
      id oldEntry = [before objectAtIndex:oldIndex];
      if ([oldEntry respondsToSelector:@selector(isSummaryEqual:)]) {
        if (![oldEntry isSummaryEqual:entry]) {
          
          // Create an operation.
          ISListViewAdapterOperation *operation =
          [ISListViewAdapterOperation new];
          
          // Update.
          operation.type =
          ISListViewAdapterOperationTypeUpdate;
          operation.currentIndex =
          [NSIndexPath indexPathForItem:i
                              inSection:0];
          operation.previousIndex =
          operation.currentIndex;
          [updates addObject:operation];
          
          // Track the update.
          updateCount++;
          
        }
      }
    }
  }
  
  assert(countBefore == countAfter);
  
  return updates;
}


- (void)updateEntries
{
  
  // Perform the update and comparison on a different thread to ensure we do
  // not block the UI thread.  Since we are always dispatching updates
  // onto a common queue we can guarantee that updates are performed in
  // order (though they may be delayed).
  // Updates are cross-posted back to the main thread.
  // We are using an ordered dispatch queue here, so it is guaranteed
  // that the current entries will not be being edited a this point.
  // As we are only performing a read, we can safely do so without
  // entering a synchronized block.
  dispatch_async(self.comparisonQueue, ^{
    
    // Only run if we believe the state is invalid.
    // TODO This is not good enough.
    @synchronized (self) {
      if (self.state == ISDBViewStateValid) {
        return;
      }
    }
    
    // Fetch the current state.
    __block NSMutableArray *entries;
    __block NSMutableArray *sections;
    __block NSMutableArray *completionEntries;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_main_queue(), ^{
      entries = [self.entries copy];
      sections = [self.sections copy];
      [self.dataSource itemsForAdapter:self
       completionBlock:^(NSArray *entries) {
         completionEntries = [entries mutableCopy];
         self.state = ISDBViewStateValid;
         dispatch_semaphore_signal(sema);
       }];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // If the data source implements the appropriate delegate methods then we assume that
    // it has not provided us with an array of ISListViewAdapterItemDescription objects
    // and instead generate our own.
    // It may be more performant to skip the generation of a new array and call these
    // selectors directly, but this allows for the new API support in the short-term.
    
    NSArray *updatedEntries =
    [self _descriptionsForItems:completionEntries];
    NSArray *updatedSections =
    [self _sectionsForItems:completionEntries];
    
    if (self.debug) {
      NSLog(@"before %lu, after:%lud",
            (unsigned long)entries.count,
            (unsigned long)updatedEntries.count);
    }
    
    
    NSArray *updates = [self _changesBetweenArray:entries
                                         andArray:updatedEntries];
    
    // Update the state and notify our observers.
    dispatch_sync(dispatch_get_main_queue(), ^{
      
//      if (self.debug) {
//        NSLog(@"additions: %ld, removals:%ld, updates:%ld, moves: %ld",
//              (long)additionCount,
//              (long)removalCount,
//              (long)updateCount,
//              (long)moveCount);
//      }
      
      // Increment the version seen.
      NSUInteger previousVersion = _version;
      _version = _version + 1;
      
      // Update the internal state.
      self.sections = updatedSections;
      self.entries = updatedEntries;
      
      
//      // Notify the observers of the additions, moves and removals.
//      self.entries = updatedEntries;
//      if (actions.count > 0) {
//        [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
//                   withObject:self
//                   withObject:actions
//                   withObject:@(previousVersion)];
//      }
//      
//      // Notify the observers of updates in a separate block to avoid
//      // performing multiple operations to individual items (it seems
//      // to break UITableView).
//      if (updates.count > 0) {
//        [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
//                   withObject:self
//                   withObject:updates
//                   withObject:@(previousVersion)];
//      }
      
      // TODO Dummy udpate. Remove.
      [self.notifier notify:@selector(adapter:performBatchUpdates:fromVersion:)
                 withObject:self
                 withObject:@[]
                 withObject:@(previousVersion)];
      
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
