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

#import "ISListViewAdapterConnector.h"
#import "ISListViewAdapterOperation.h"
#import "ISListViewAdapter.h"

@interface ISListViewAdapterConnector () {
  NSInteger _currentVersion;
  BOOL _initialized;
}

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) ISListViewAdapter *adapter;
@property (nonatomic) UITableViewRowAnimation animation;

@end

@implementation ISListViewAdapterConnector

+ (id)connectorWithAdapter:(ISListViewAdapter *)adapter
            collectionView:(UICollectionView *)collectionView
{
  return [[self alloc] initWithAdapter:adapter
                        collectionView:collectionView];
}

- (id)initWithAdapter:(ISListViewAdapter *)adapter
       collectionView:(UICollectionView *)collectionView
{
  self = [super init];
  if (self) {
    self.adapter = adapter;
    self.collectionView = collectionView;
    [self.adapter addAdapterObserver:self];
    _initialized = NO;
    _currentVersion = 0;
  }
  return self;
}


+ (id)connectorWithAdapter:(ISListViewAdapter *)adapter
                 tableView:(UITableView *)tableView
{
  return [[self alloc] initWithAdapter:adapter
                             tableView:tableView];
}


- (id)initWithAdapter:(ISListViewAdapter *)adapter
           tableView:(UITableView *)tableView
{
  self = [super init];
  if (self) {
    self.adapter = adapter;
    self.tableView = tableView;
    self.animation = UITableViewRowAnimationAutomatic;
    [self.adapter addAdapterObserver:self];
    _initialized = NO;
    _currentVersion = 0;
  }
  return self;
}


- (NSUInteger)count
{
  if (!_initialized) {
    _initialized = YES;
  }
  _currentVersion = self.adapter.version;
  return self.adapter.count;
}


- (void)reloadData
{
  if (self.collectionView) {
    [self.collectionView reloadData];
  } else if (self.tableView) {
    [self.tableView reloadData];
  }
}


#pragma mark - ISListViewAdapterObserver


- (void)performBatchUpdates:(NSArray *)updates
                fromVersion:(NSNumber *)version
{;
  // If a UICollectionView or UITableView are notified of batch
  // updates _before_ they have been shown, then they will ask
  // for the count twice during the update and expect different
  // values each time.
  // We identify this scenario by tracking the _initialized
  // parameter. This is set when we are first queried for our
  // count (meaning that it is only safe to query for the count
  // when asked by the UITableView or UICollectionView).
  // While we could do something clever like attempt to guess
  // the expected count, it is safer to just force a complete
  // reload of the data, espeicially since it won't cause any
  // missed animations.
  // The other mis-matches which may occur are handled by the
  // adapter versioning which will ensure we correctly ignore
  // non-incremental updates (see below).
  if (!_initialized) {
    [self reloadData];
    return;
  }
  
  // Handle non-incremental version updates.
  NSUInteger updateFromVersion = [version integerValue];
  if (updateFromVersion > _currentVersion) {
    // We are out of date: force a complete update.
    [self reloadData];
    return;
  } else if (updateFromVersion < _currentVersion) {
    // Simply ignore the update and wait to catch up.
    return;
  }
  
  if (self.collectionView) {
    
    [self.collectionView performBatchUpdates:^{
      for (ISListViewAdapterOperation *operation in updates) {
        if (operation.type ==
            ISListViewAdapterOperationTypeInsert) {
          [self.collectionView insertItemsAtIndexPaths:@[operation.currentIndex]];
        } else if (operation.type ==
                   ISListViewAdapterOperationTypeMove) {
          [self.collectionView moveItemAtIndexPath:operation.previousIndex
                                       toIndexPath:operation.currentIndex];
        } else if (operation.type ==
                   ISListViewAdapterOperationTypeDelete) {
          [self.collectionView deleteItemsAtIndexPaths:@[operation.previousIndex]];
        } else if (operation.type ==
                   ISListViewAdapterOperationTypeUpdate) {
          [self.collectionView reloadItemsAtIndexPaths:@[operation.currentIndex]];
        } else {
          NSLog(@"Unsupported operation: %@", operation);
        }
      }
    } completion:NULL];
    
  } else if (self.tableView) {
    
    [self.tableView beginUpdates];
    
    for (ISListViewAdapterOperation *operation in updates) {
      if (operation.type ==
          ISListViewAdapterOperationTypeInsert) {
        [self.tableView insertRowsAtIndexPaths:@[operation.currentIndex]
                              withRowAnimation:self.animation];
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeMove) {
        [self.tableView moveRowAtIndexPath:operation.previousIndex
                               toIndexPath:operation.currentIndex];
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeDelete) {
        [self.tableView deleteRowsAtIndexPaths:@[operation.previousIndex]
                              withRowAnimation:self.animation];
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeUpdate) {
        [self.tableView reloadRowsAtIndexPaths:@[operation.currentIndex]
                              withRowAnimation:self.animation];
      } else {
        NSLog(@"Unsupported operation: %@", operation);
      }
    }
    
    [self.tableView endUpdates];
    
  }
}


@end
