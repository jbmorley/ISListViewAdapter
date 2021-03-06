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

#import "ISTestDataSource.h"
#import <ISUtilities/ISUtilities.h>

@interface ISTestDataSource ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *current;
@property (nonatomic, strong) ISListViewAdapterInvalidator *invalidator;
@property (nonatomic, assign) NSUInteger iteration;

@end

#define MIN_ITEMS 10
#define MAX_ITEMS 20

static NSString *const kSectionTitle = @"title";
static NSString *const kSectionItems = @"items";
static NSString *const kItemIdentifier = @"identifier";
static NSString *const kItemColor = @"color";

@implementation ISTestDataSource

- (id)init
{
  self = [super init];
  if (self) {
    self.sections =
    @[@{kSectionTitle: @"Section One",
        kSectionItems: @[@{kItemIdentifier:@"A"},
                         @{kItemIdentifier:@"B"},
                         @{kItemIdentifier:@"C"},
                         @{kItemIdentifier:@"D"},
                         @{kItemIdentifier:@"E"}]},
      @{kSectionTitle: @"Section Two",
        kSectionItems: @[@{kItemIdentifier:@"F"},
                         @{kItemIdentifier:@"G"},
                         @{kItemIdentifier:@"H"}]},
      @{kSectionTitle: @"Section Three",
        kSectionItems: @[@{kItemIdentifier:@"I"},
                         @{kItemIdentifier:@"J"},
                         @{kItemIdentifier:@"K"},
                         @{kItemIdentifier:@"L"},
                         @{kItemIdentifier:@"M"}]},
      @{kSectionTitle: @"Section Four",
        kSectionItems: @[@{kItemIdentifier:@"N"},
                         @{kItemIdentifier:@"O"}]}];
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
    NSArray *tempItems = [self _randomSelection:section[kSectionItems] toggle:self.togglesItems move:self.movesItems];
    
    // Set the colors:
    NSMutableArray *sectionItems = [NSMutableArray arrayWithCapacity:tempItems.count];
    for (NSDictionary *item in tempItems) {
      NSMutableDictionary *mutableItem = [item mutableCopy];
      if (self.updatesItems) {
        mutableItem[kItemColor] = ((arc4random() % 2) == 0) ? @"Cyan" : @"Yellow";
      } else {
        mutableItem[kItemColor] = @"Cyan";
      }
      [sectionItems addObject:mutableItem];
    }
    
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


#pragma mark - ISListViewAdapter


- (void)adapter:(ISListViewAdapter *)adapter
     initialize:(ISListViewAdapterInvalidator *)invalidator
{
  self.invalidator = invalidator;
}


- (void)identifiersForAdapter:(ISListViewAdapter *)adapter completionBlock:(ISListViewAdapterBlock)completionBlock
{
  [self _generateState];
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSDictionary *section in self.current) {
    for (NSDictionary *item in section[kSectionItems]) {
      [items addObject:item[kItemIdentifier]];
    }
  }
  
  NSLog(@"%@", [self arrayToJSON:self.current]);
  
  completionBlock(items);
}


- (NSString *)arrayToJSON:(NSArray *)array
{
  NSData* data =
  [NSJSONSerialization dataWithJSONObject:array
                                  options:0
                                    error:nil];
  NSString* string =
  [[NSString alloc] initWithBytes:[data bytes]
                           length:[data length]
                         encoding:NSUTF8StringEncoding];
  return string;
}


- (void)adapter:(ISListViewAdapter *)adapter
itemForIdentifier:(id)identifier
completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock([self itemForIdentifier:identifier]);
}


- (id)adapter:(ISListViewAdapter *)adapter summaryForIdentifier:(id)identifier
{
  NSDictionary *item = [self itemForIdentifier:identifier];
  return item[kItemColor];
}


- (NSString *)adapter:(ISListViewAdapter *)adapter sectionForIdentifier:(id)identifier
{
  for (NSDictionary *section in self.current) {
    for (NSDictionary *i in section[kSectionItems]) {
      if ([i[kItemIdentifier] isEqual:identifier]) {
        return section[kSectionTitle];
      }
    }
  }
  return nil;
}


- (NSDictionary *)itemForIdentifier:(NSString *)identifier
{
  for (NSDictionary *section in self.current) {
    for (NSDictionary *i in section[kSectionItems]) {
      if ([i[kItemIdentifier] isEqual:identifier]) {
        return i;
      }
    }
  }
  return nil;
}


- (BOOL)next
{
  [self.invalidator invalidate];
  self.iteration++;
  if (self.iterations == 0) {
    return YES;
  } else {
    return (self.iteration < self.iterations);
  }
}


@end
