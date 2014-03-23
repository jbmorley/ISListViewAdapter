//
//  ISListViewAdapterChanges.m
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import "ISListViewAdapterChanges.h"
#import "ISListViewAdapterOperation.m"

@implementation ISListViewAdapterChanges

- (id)init
{
  self = [super init];
  if (self) {
    NSLog(@"New Change:");
    self.changes = [NSMutableArray arrayWithCapacity:3];
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
  NSLog(@"%@", operation);
  [self.changes addObject:operation];
}


- (void)insertSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeInsertSection;
  operation.indexPath =
  [NSIndexPath indexPathForItem:0 inSection:section];
  NSLog(@"%@", operation);
  [self.changes addObject:operation];

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
  NSLog(@"%@", operation);
  [self.changes addObject:operation];
}


- (void)deleteItem:(NSInteger)item
         inSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeDeleteItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  NSLog(@"%@", operation);
  [self.changes addObject:operation];
}


- (void)insertItem:(NSInteger)item
         inSection:(NSInteger)section
{
  ISListViewAdapterOperation *operation = [self _operation];
  operation.type = ISListViewAdapterOperationTypeInsertItem;
  operation.indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  NSLog(@"%@", operation);
  [self.changes addObject:operation];
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
  NSLog(@"%@", operation);
  [self.changes addObject:operation];
}


- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation
{
  [tableView beginUpdates];
  
  for (ISListViewAdapterOperation *operation in self.changes) {
  
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
      
      // TODO Update.
      
    }
    
  }
    
  [tableView endUpdates];
}

- (void)applyToCollectionView:(UICollectionView *)collectionView
{
  
  [collectionView performBatchUpdates:^{

    for (ISListViewAdapterOperation *operation in self.changes) {
      
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
        
        // TODO Update.
        
      }
      
    }
    
  } completion:NULL];

}

@end
