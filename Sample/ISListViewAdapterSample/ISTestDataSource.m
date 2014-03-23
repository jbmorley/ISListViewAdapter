//
//  ISSectionsDataSource.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISTestDataSource.h"

@interface ISTestDataSource ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *current;

@end

#define MIN_ITEMS 10
#define MAX_ITEMS 20

static NSString *const kSectionTitle = @"title";
static NSString *const kSectionItems = @"items";

@implementation ISTestDataSource

- (id)init
{
  self = [super init];
  if (self) {
    self.sections =
    @[@{kSectionTitle: @"Section One",
        kSectionItems: @[@"A", @"B", @"C", @"D", @"E"]},
      @{kSectionTitle: @"Section Two",
        kSectionItems: @[@"F", @"G", @"H"]},
      @{kSectionTitle: @"Section Three",
        kSectionItems: @[@"I", @"J", @"K", @"L", @"M"]},
      @{kSectionTitle: @"Section Four",
        kSectionItems: @[@"N", @"O"]}];
  }
  return self;
}


- (void)_generateState
{
  // 'Shuffle' the sections.
  NSArray *sections =
  [self _randomSelection:self.sections
                  toggle:self.togglesSections
                    move:self.movesSections];
  
  // 'Shuffle' the items.
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSDictionary *section in sections) {
    NSArray *sectionItems = [self _randomSelection:section[kSectionItems] toggle:self.togglesItems move:self.movesItems];
    NSDictionary *newSection = @{kSectionTitle: section[kSectionTitle], kSectionItems: sectionItems};
    [items addObject:newSection];
  }
  
  assert(items.count == sections.count);
  
  self.current = items;
}


- (NSArray *)_randomSelection:(NSArray *)array
                       toggle:(BOOL)toggle
                         move:(BOOL)move
{
  NSMutableArray *order =
  [NSMutableArray arrayWithCapacity:3];
  if (move) {
    NSMutableArray *candidates = [array mutableCopy];
    while (candidates.count) {
      NSUInteger index = arc4random() % candidates.count;
      NSDictionary *section = [candidates objectAtIndex:index];
      [order addObject:section];
      [candidates removeObjectAtIndex:index];
    }
  } else {
    order = [array mutableCopy];
  }
  
  NSMutableArray *result =
  [NSMutableArray arrayWithCapacity:3];
  if (toggle) {
    for (NSDictionary *item in order) {
      int include = arc4random() % 2;
      if (include) {
        [result addObject:item];
      }
    }
    
    // Enusre we always have at least one.
    if (result.count == 0) {
      int index = arc4random() % order.count;
      [result addObject:order[index]];
    }
    
  } else {
    result = order;
  }
  
  return result;

}


- (void)itemsForAdapter:(ISListViewAdapter *)adapter completionBlock:(ISListViewAdapterBlock)completionBlock
{
  [self _generateState];
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSDictionary *section in self.current) {
    for (NSString *item in section[kSectionItems]) {
      [items addObject:item];
    }
  }
  completionBlock(items);
}


- (id)adapter:(ISListViewAdapter *)adapter identifierForItem:(id)item
{
  return item;
}


- (void)adapter:(ISListViewAdapter *)adapter itemForIdentifier:(id)identifier completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock(identifier);
}


- (id)adapter:(ISListViewAdapter *)adapter summaryForItem:(id)item
{
  return @" ";
}


- (NSString *)adapter:(ISListViewAdapter *)adapter sectionForItem:(id)item
{
  for (NSDictionary *section in self.current) {
    for (NSString *i in section[kSectionItems]) {
      if ([i isEqual:item]) {
        return section[kSectionTitle];
      }
    }
  }
  return nil;
}

@end
