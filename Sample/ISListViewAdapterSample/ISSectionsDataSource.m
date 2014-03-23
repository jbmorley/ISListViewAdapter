//
//  ISSectionsDataSource.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISSectionsDataSource.h"

@interface ISSectionsDataSource ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *current;
@property (nonatomic, weak) ISListViewAdapter *adapter;

@end

#define MIN_ITEMS 10
#define MAX_ITEMS 20

static NSString *const kSectionTitle = @"title";
static NSString *const kSectionItems = @"items";

@implementation ISSectionsDataSource

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


- (void)_reload
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.adapter invalidate];
    [self _reload];
  });
}


- (void)_generateState
{
  self.current = [NSMutableArray arrayWithCapacity:3];
  if (self.movesSections) {
    NSMutableArray *candidates = [self.sections mutableCopy];
    while (candidates.count) {
      NSUInteger index = arc4random() % candidates.count;
      NSDictionary *section = [candidates objectAtIndex:index];
      [self.current addObject:section];
      [candidates removeObjectAtIndex:index];
    }
  } else {
    for (NSDictionary *section in self.sections) {
      int include = arc4random() % 2;
      if (include) {
        [self.current addObject:section];
      }
    }
  }
}


- (NSString *)_randomSection
{
  NSUInteger index = arc4random() % self.sections.count;
  return self.sections[index];
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


- (void)initializeAdapter:(ISListViewAdapter *)adapter
{
  self.adapter = adapter;
  [self _reload];
}

@end
