//
//  ISListViewAdapterTests.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <ISUtilities/ISUtilities.h>
#import "ISListViewAdapterTests.h"
#import "ISTestDataSource.h"
#import "ISRandomDataSource.h"

NSString *const kSourceTitle = @"title";
NSString *const kSourceDataSource = @"dataSource";

@interface ISListViewAdapterTests ()

@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) NSArray *sources;
@property (nonatomic, assign) NSUInteger test;
@property (nonatomic, assign) NSUInteger count;

@end

#define ITERATIONS 100

#define TEST_SECTIONS
#define TEST_ITEMS
#define TEST_ALL
#define TEST_RANDOM

@implementation ISListViewAdapterTests


- (ISListViewAdapter *)testAdapter
{
  if (self.adapter == nil) {
    self.sources = [self testDataSources];
    self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self.sources[0][kSourceDataSource]];
  }
  return self.adapter;
}

- (void)start
{
  [self _reload];
}


- (void)_reload
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.32 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
    [self.delegate willStartTest:[NSString stringWithFormat:@"%@ - %d", self.sources[self.test][kSourceTitle], self.count]];
     self.count++;
    
    if (self.count >= ITERATIONS) {
      self.test = self.test + 1;
      self.count = 0;
      if (self.test < self.sources.count) {
        [self.adapter transitionToDataSource:self.sources[self.test][kSourceDataSource]];
      }
    } else {
      [self.adapter invalidate];
    }
    
    if (self.test < self.sources.count) {
      [self _reload];
    } else {
      [[[UIAlertView alloc] initWithTitle:@"PASSED" message:@"Well done!" completionBlock:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
  });
}


- (NSArray *)testDataSources
{
  NSMutableArray *dataSources =
  [NSMutableArray arrayWithCapacity:3];
  
#ifdef TEST_SECTIONS
  
  // Static sections.
  [dataSources addObject:
   @{kSourceTitle: @"Sections",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    return dataSource;
  }()}];

  // Section insertions and deletions.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = NO;
    return dataSource;
  }()}];

  // Section moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = YES;
    return dataSource;
  }()}];

  // Section insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d/m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = YES;
    return dataSource;
  }()}];
  
#endif
  
#ifdef TEST_ITEMS

  // Static items.
  [dataSources addObject:
   @{kSourceTitle: @"Items",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = NO;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];

  // Item insertions and deletions.
  [dataSources addObject:
   @{kSourceTitle: @"Items (i/d)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = YES;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];

  // Item moves.
  [dataSources addObject:
   @{kSourceTitle: @"Items (m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = NO;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];

  // Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Items (i/d/m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = YES;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
#endif
  
#ifdef TEST_ALL
  
  // Section moves, Item insertions and deletions.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d), Items (i/d)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = NO;
    dataSource.togglesItems = YES;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d), Items (m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = NO;
    dataSource.togglesItems = NO;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d), Items (i/d/m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = NO;
    dataSource.togglesItems = YES;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions and deletions.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (m), Items (i/d)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = YES;
    dataSource.togglesItems = YES;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (m), Items (m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = YES;
    dataSource.togglesItems = NO;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (m), Items (i/d/m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = YES;
    dataSource.togglesItems = YES;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
  // Section moves, Item insertions, deletions and moves.
  [dataSources addObject:
   @{kSourceTitle: @"Sections (i/d/m), Items (i/d/m)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = YES;
    dataSource.togglesItems = YES;
    dataSource.movesItems = YES;
    return dataSource;
  }()}];
  
#endif
  
#ifdef TEST_RANDOM
  
  // Static sections.
  [dataSources addObject:
   @{kSourceTitle: @"Random",
     kSourceDataSource: ^(){
    ISRandomDataSource *dataSource =
    [ISRandomDataSource new];
    return dataSource;
  }()}];
  
#endif
  
  return dataSources;

}

@end
