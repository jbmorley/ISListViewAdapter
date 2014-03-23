//
//  ISRandomDataSource.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 22/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISRandomDataSource.h"

@interface ISRandomDataSource ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *candidates;
@property (nonatomic, weak) ISListViewAdapter *adapter;

@end

#define MIN_ITEMS 10
#define MAX_ITEMS 20

@implementation ISRandomDataSource

- (id)init
{
  self = [super init];
  if (self) {
    self.sections = @[@"ONE", @"TWO", @"THREE", @"FOUR"];
  }
  return self;
}


- (void)_reload
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.adapter invalidate];
    [self _reload];
  });
}


- (void)_populateCandidates
{
  self.candidates = [@[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"] mutableCopy];
}


- (NSString *)_randomSection
{
  NSUInteger index = arc4random() % self.sections.count;
  return self.sections[index];
}


- (void)itemsForAdapter:(ISListViewAdapter *)adapter completionBlock:(ISListViewAdapterBlock)completionBlock
{
  [self _populateCandidates];
  
  NSMutableArray *items =
  [NSMutableArray arrayWithCapacity:MAX_ITEMS];
  NSUInteger randomSize = MAX_ITEMS - MIN_ITEMS;
  NSUInteger random = arc4random() % randomSize;
  NSUInteger count = MIN_ITEMS + random;
  
  for (int i = 0; i < count; i++) {
    int index = arc4random() % self.candidates.count;
    [items addObject:self.candidates[index]];
    [self.candidates removeObjectAtIndex:index];
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
  return [self _randomSection];
}


- (void)initializeAdapter:(ISListViewAdapter *)adapter
{
  self.adapter = adapter;
  [self _reload];
}


@end
