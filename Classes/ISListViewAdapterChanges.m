//
//  ISListViewAdapterChanges.m
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import "ISListViewAdapterChanges.h"

@implementation ISListViewAdapterSectionMove

@end

@implementation ISListViewAdapterChanges

- (id)init
{
  self = [super init];
  if (self) {
    self.sectionDeletions = [NSMutableIndexSet indexSet];
    self.sectionInsertions = [NSMutableIndexSet indexSet];
    self.sectionMoves = [NSMutableArray arrayWithCapacity:3];
    self.itemDeletions = [NSMutableArray arrayWithCapacity:3];
    self.itemInsertions = [NSMutableArray arrayWithCapacity:3];
  }
  return self;
}


- (void)deleteSection:(NSInteger)section
{
  [self.sectionDeletions addIndex:section];
}


- (void)insertSection:(NSInteger)section
{
  [self.sectionInsertions addIndex:section];
}


- (void)moveSection:(NSInteger)section
          toSection:(NSInteger)newSection
{
  ISListViewAdapterSectionMove *move =
  [ISListViewAdapterSectionMove new];
  move.section = section;
  move.newSection = newSection;
  [self.sectionMoves addObject:move];
}


- (void)deleteItem:(NSInteger)item
         inSection:(NSInteger)section
{
  NSIndexPath *indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  [self.itemDeletions addObject:indexPath];
}


- (void)insertItem:(NSInteger)item
         inSection:(NSInteger)section
{
  NSIndexPath *indexPath =
  [NSIndexPath indexPathForItem:item inSection:section];
  [self.itemInsertions addObject:indexPath];
}


- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation
{
  [tableView beginUpdates];
  
  // Items.
  [tableView deleteRowsAtIndexPaths:self.itemDeletions
                   withRowAnimation:animation];
  [tableView insertRowsAtIndexPaths:self.itemInsertions
                   withRowAnimation:animation];
  
  // Sections.
  [tableView deleteSections:self.sectionDeletions
                withRowAnimation:animation];
  [tableView insertSections:self.sectionInsertions
                withRowAnimation:animation];
  for (ISListViewAdapterSectionMove *move in
       self.sectionMoves) {
    [tableView moveSection:move.section
                 toSection:move.newSection];
  }
  
  [tableView endUpdates];
}

@end
