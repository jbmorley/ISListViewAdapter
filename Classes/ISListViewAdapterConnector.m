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

@interface ISListViewAdapterConnector ()

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic) UITableViewRowAnimation animation;

@end

@implementation ISListViewAdapterConnector

+ (id)connectorWithCollectionView:(UICollectionView *)collectionView
{
  return [[self alloc] initWithCollectionView:collectionView];
}

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
  self = [super init];
  if (self) {
    self.collectionView = collectionView;
  }
  return self;
}


+ (id)connectorWithTableView:(UITableView *)tableView
{
  return [[self alloc] initWithTableView:tableView];
}


- (id)initWithTableView:(UITableView *)tableView
{
  self = [super init];
  if (self) {
    self.tableView = tableView;
    self.animation = UITableViewRowAnimationAutomatic;
  }
  return self;
}


#pragma mark - ISListViewAdapterObserver


- (void)performBatchUpdates:(NSArray *)updates
{
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
