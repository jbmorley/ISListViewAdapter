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

#import "ISListViewAdapterChanges.h"
#import "ISListViewAdapterOperation.h"

@interface ISListViewAdapterChanges ()

@property (nonatomic, weak) id<ISListViewAdapterLogger> logger;

@end

@implementation ISListViewAdapterChanges


+ (id)changesWithLogger:(id<ISListViewAdapterLogger>)logger
{
  return [[self alloc] initWithLogger:logger];
}


- (id)initWithLogger:(id<ISListViewAdapterLogger>)logger
{
  self = [super init];
  if (self) {
    self.logger = logger;
    [self.logger log:@"Creating new ISListViewAdapterChanges"];
    self.operations = [NSMutableArray arrayWithCapacity:3];
  }
  return self;
}


- (ISListViewAdapterOperation *)_operation
{
  return [ISListViewAdapterOperation new];
}


- (void)deleteSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeDeleteSection;
  operation.indexPath =
  [NSIndexPath indexPathForItem:0 inSection:section];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)insertSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeInsertSection;
  operation.indexPath =
  [NSIndexPath indexPathForItem:0 inSection:section];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];

}


- (void)moveSection:(NSInteger)section
          toSection:(NSInteger)toSection
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeMoveSection;
  operation.indexPath =
  [NSIndexPath indexPathForItem:0 inSection:section];
  operation.toIndexPath =
  [NSIndexPath indexPathForItem:0 inSection:toSection];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)deleteItem:(NSInteger)item
         inSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeDeleteItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)insertItem:(NSInteger)item
         inSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeInsertItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)moveItem:(NSInteger)item
       inSection:(NSInteger)section
          toItem:(NSInteger)toItem
       inSection:(NSInteger)toSection
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeMoveItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  operation.toIndexPath =
  [NSIndexPath indexPathForItem:toItem inSection:toSection];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)updateItem:(NSInteger)item
         inSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeUpdateItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  [self.logger log:@"%@", operation];
  [self.operations addObject:operation];
}


- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation
{
  [tableView beginUpdates];
  
  for (ISListViewAdapterOperation *operation in self.operations) {
  
    if (operation.type ==
        ISListViewAdapterOperationTypeDeleteSection) {
      
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:operation.indexPath.section] withRowAnimation:animation];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeInsertSection) {

      [tableView insertSections:[NSIndexSet indexSetWithIndex:operation.indexPath.section] withRowAnimation:animation];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeMoveSection) {
      
      [tableView moveSection:operation.indexPath.section toSection:operation.toIndexPath.section];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeDeleteItem) {
      
      [tableView deleteRowsAtIndexPaths:@[operation.indexPath] withRowAnimation:animation];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeInsertItem) {
      
      [tableView insertRowsAtIndexPaths:@[operation.indexPath] withRowAnimation:animation];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeMoveItem) {
      
      [tableView moveRowAtIndexPath:operation.indexPath toIndexPath:operation.toIndexPath];
      
    } else if (operation.type ==
               ISListViewAdapterOperationTypeUpdateItem) {
      
      [tableView reloadRowsAtIndexPaths:@[operation.indexPath] withRowAnimation:animation];
      
    }
    
  }
    
  [tableView endUpdates];
}

- (void)applyToCollectionView:(UICollectionView *)collectionView
{
  [self.logger log:@"Changes: %@", self.operations];
  
  [collectionView performBatchUpdates:^{

    for (ISListViewAdapterOperation *operation in self.operations) {
      
      if (operation.type ==
          ISListViewAdapterOperationTypeDeleteSection) {
        
        [collectionView deleteSections:[NSIndexSet indexSetWithIndex:operation.indexPath.section]];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeInsertSection) {
        
        [collectionView insertSections:[NSIndexSet indexSetWithIndex:operation.indexPath.section]];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeMoveSection) {
        
        [collectionView moveSection:operation.indexPath.section toSection:operation.toIndexPath.section];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeDeleteItem) {
        
        [collectionView deleteItemsAtIndexPaths:@[operation.indexPath]];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeInsertItem) {
        
        [collectionView insertItemsAtIndexPaths:@[operation.indexPath]];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeMoveItem) {
        
        [collectionView moveItemAtIndexPath:operation.indexPath toIndexPath:operation.toIndexPath];
        
      } else if (operation.type ==
                 ISListViewAdapterOperationTypeUpdateItem) {
        
        [collectionView reloadItemsAtIndexPaths:@[operation.indexPath]];
        
      }
      
    }
    
  } completion:NULL];

}


- (BOOL)empty
{
  return (self.operations.count == 0);
}


- (NSString *)description
{
  NSMutableArray *changes =
  [NSMutableArray arrayWithCapacity:self.operations.count];
  for (ISListViewAdapterOperation *op in self.operations) {
    [changes addObject:[op description]];
  }
  return [changes componentsJoinedByString:@"\n"];
}


@end
