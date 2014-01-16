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

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;


@interface ISListViewAdapter ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) id<ISListViewAdapterDataSource> dataSource;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic) dispatch_queue_t comparisonQueue;

@end

NSInteger ISDBViewIndexUndefined = -1;

@implementation ISListViewAdapter


- (id)initWithDataSource:(id<ISListViewAdapterDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
    self.entries = @[];
    
    if ([self.dataSource respondsToSelector:@selector(initialize:)]) {
      [self.dataSource initialize:self];
    }
    
    // Create a worker queue on which to perform the
    // item comparison. We may wish to share a global queue
    // across multiple instances by using a default worker.
    NSString *queueIdentifier = [NSString stringWithFormat:@"%@%p",
                                 @"uk.co.inseven.view.",
                                 self];
    self.comparisonQueue
    = dispatch_queue_create([queueIdentifier UTF8String], NULL);
    
    [self updateEntries];
  }
  return self;
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


- (void)updateEntries
{
  // Only run if we're not currently updating the entries.
  @synchronized (self) {
    if (self.state == ISDBViewStateValid) {
      return;
    } else {
      self.state = ISDBViewStateValid;
    }
  }
  
  // Copy our existing view of the entries to ensure it doesn't
  // change while we are procesisng the change sets.
  NSMutableArray *entries = [self.entries mutableCopy];
  
  // Fetch the updated entries.
  [self.dataSource adapter:self
          entriesForOffset:0
                     limit:-1
   complectionBlock:^(NSArray *updatedEntries) {

     // Cross-post the comparison onto a separate serial dispatch queue.
     // This ensures all updates are ordered.
     dispatch_async(self.comparisonQueue, ^{
       
       // Perform the comparison on a different thread to ensure we do
       // not block the UI thread.  Since we are always dispatching updates
       // onto a common queue we can guarantee that updates are performed in
       // order (though they may be delayed).
       // Updates are cross-posted back to the main thread.
       // We are using an ordered dispatch queue here, so it is guaranteed
       // that the current entries will not be being edited a this point.
       // As we are only performing a read, we can safely do so without
       // entering a synchronized block.
       NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
       NSMutableArray *updates = [NSMutableArray arrayWithCapacity:3];
       NSInteger countBefore = entries.count;
       NSInteger countAfter = updatedEntries.count;
              
       // Removes and moves.
       for (NSInteger i = entries.count-1; i >= 0; i--) {
         ISListViewAdapterItemDescription *entry =
         [entries objectAtIndex:i];
         
         // Determine the type of the operation.
         NSUInteger newIndex =
         [updatedEntries indexOfObject:entry];
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
           
         }
       }
       
       // Additions and updates.
       for (NSUInteger i = 0; i < updatedEntries.count; i++) {
         ISListViewAdapterItemDescription *entry =
         [updatedEntries objectAtIndex:i];
         
         // Determine the index of the operation.
         NSUInteger oldIndex =
         [entries indexOfObject:entry];
         
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
           
         } else {
           
           // Check for updates.
           ISListViewAdapterItemDescription *oldEntry =
           [entries objectAtIndex:oldIndex];
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
             
           }
         }
       }
       
       assert(countBefore == countAfter);
       
       // Update the state and notify our observers.
       dispatch_async(dispatch_get_main_queue(), ^{
         
         // Notify the observers of the additions, moves and removals.
         self.entries = updatedEntries;
         [self.notifier notify:@selector(performBatchUpdates:)
                    withObject:actions];
         
         // Notify the observers of updates in a separate block to avoid
         // performing multiple operations to individual items (it seems
         // to break UITableView).
         [self.notifier notify:@selector(performBatchUpdates:)
                    withObject:updates];
         
       });
       
     });
     
   }];
}


- (NSUInteger)count
{
  // We may return an out-of-date result for the count, but we fire an
  // asynchronous update which will ensure we return the latest version
  // as-and-when it is available.
  // TODO How do we ensure we're up-to-date and that there aren't any outstanding
  // updates? Perhaps we could count the update requests and zero it every time
  // we attempt ot make an actual update? Or is this over-engineering?
  [self updateEntries];
  return self.entries.count;
}


- (ISListViewAdapterItem *)itemForIdentifier:(id)identifier
{
  // Create a description to allow us to find the entry.
  ISListViewAdapterItemDescription *description
  = [ISListViewAdapterItemDescription descriptionWithIdentifier:identifier
                                            summary:nil];
  NSUInteger index = [self.entries indexOfObject:description];
  ISListViewAdapterItem *entry = [ISListViewAdapterItem entryWithAdapter:self
                                        index:index
                                   identifier:identifier];
  return entry;
}


- (ISListViewAdapterItem *)itemForIndex:(NSInteger)index
{
  ISListViewAdapterItem *entry = [ISListViewAdapterItem entryWithAdapter:self
                                        index:index];
  return entry;
}


#pragma mark - Observers


- (void)addObserver:(id<ISListViewAdapterObserver>)observer
{
  [self.notifier addObserver:observer];
}


- (void)removeObserver:(id<ISListViewAdapterObserver>)observer
{
  [self.notifier removeObserver:observer];
}


@end
