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

#import "ISRandomDataSource.h"

@interface ISRandomDataSource ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *candidates;

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


@end
