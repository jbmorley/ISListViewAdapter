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

#import <ISUtilities/ISUtilities.h>
#import "ISListViewAdapterTests.h"
#import "ISTestDataSource.h"
#import "ISRandomDataSource.h"
#import "ISSingleTestDataSource.h"
#import "ISCommonDataSource.h"

NSString *const kSourceTitle = @"title";
NSString *const kSourceDataSource = @"dataSource";

@interface ISListViewAdapterTests ()

@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) NSArray *sources;
@property (nonatomic, assign) NSUInteger test;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) BOOL currentDataSourceComplete;

@end

#define DEFAULT_ITERATIONS 50

#define TEST_SPECIAL_CASES
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
    self.adapter.debug = YES;
  }
  return self.adapter;
}

- (void)start
{
  [self _reload];
}


- (void)_reload
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(0.32 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    
    [self.delegate willStartTest:[NSString stringWithFormat:@"%@ - %d", self.sources[self.test][kSourceTitle], self.count]];
     self.count++;
    
    if (self.currentDataSourceComplete) {
      self.test = self.test + 1;
      self.count = 0;
      self.currentDataSourceComplete = NO;
      if (self.test < self.sources.count) {
        [self.adapter transitionToDataSource:self.sources[self.test][kSourceDataSource]];
      }
    } else {
      id<ISCommonDataSource> dataSource = self.sources[self.test][kSourceDataSource];
      self.currentDataSourceComplete = ![dataSource next];
    }
    
    if (self.test < self.sources.count) {
      [self _reload];
    } else {
      [self.completionDelegate testsDidFinish:self
                                      success:YES];
    }    
  });
}


- (NSArray *)testDataSources
{
  NSMutableArray *dataSources =
  [NSMutableArray arrayWithCapacity:3];
  
#ifdef TEST_SPECIAL_CASES

  // Special-case tests.
  
  [dataSources addObject:
   @{kSourceTitle: @"Sections",
     kSourceDataSource: ^(){
    ISSingleTestDataSource *dataSource =
    [[ISSingleTestDataSource alloc] initWithInitialState:@"[{\"title\":\"Section Four\",\"items\":[\"O\"]},{\"title\":\"Section Three\",\"items\":[\"I\",\"M\"]},{\"title\":\"Section One\",\"items\":[\"A\",\"B\",\"D\",\"E\"]},{\"title\":\"Section Two\",\"items\":[\"H\"]}]" finalState:@"[{\"title\":\"Section Two\",\"items\":[\"F\",\"H\"]},{\"title\":\"Section Four\",\"items\":[\"O\"]},{\"title\":\"Section Three\",\"items\":[\"M\"]},{\"title\":\"Section One\",\"items\":[\"C\"]}]"];
    return dataSource;
  }()}];
  
#endif
  
#ifdef TEST_SECTIONS
  
  // Static sections.
  [dataSources addObject:
   @{kSourceTitle: @"Sections",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.iterations = 2;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = 2;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
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
    dataSource.iterations = DEFAULT_ITERATIONS;
    return dataSource;
  }()}];
  
#endif
  
  return dataSources;

}

@end
