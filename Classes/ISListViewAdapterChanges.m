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

@end
