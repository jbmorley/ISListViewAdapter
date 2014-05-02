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

#import "ISSingleTestDataSource.h"

@interface ISSingleTestDataSource ()

@property (nonatomic, strong) NSMutableArray *states;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) ISListViewAdapterInvalidator *invalidator;


@end

static NSString *const kSectionTitle = @"title";
static NSString *const kSectionItems = @"items";

@implementation ISSingleTestDataSource

- (id)initWithInitialState:(NSString *)initialState
                finalState:(NSString *)finalState
{
  self = [super init];
  if (self) {
    self.states = [NSMutableArray arrayWithCapacity:3];
    [self.states addObject:[self fromJSON:initialState]];
    [self.states addObject:[self fromJSON:finalState]];
    self.index = 0;
  }
  return self;
}


- (NSArray *)fromJSON:(NSString *)JSON
{
  NSData *data = [JSON dataUsingEncoding:NSUTF8StringEncoding];
  NSArray *array =
  [NSJSONSerialization JSONObjectWithData:data
                                  options:0
                                    error:nil];
  return array;
}


- (NSArray *)stateForIndex:(NSUInteger)index
{
  assert(index < self.states.count);
  return self.states[index];
}


- (BOOL)next
{
  self.index++;
  [self.invalidator invalidate];
  return (self.index < (self.states.count - 1));
}


#pragma mark - ISListViewAdapterDataSource


- (void)adapter:(ISListViewAdapter *)adapter
     initialize:(ISListViewAdapterInvalidator *)invalidator
{
  self.invalidator = invalidator;
}


- (void)itemsForAdapter:(ISListViewAdapter *)adapter completionBlock:(ISListViewAdapterBlock)completionBlock
{
  NSArray *current = [self stateForIndex:self.index];
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSDictionary *section in current) {
    for (NSString *item in section[kSectionItems]) {
      [items addObject:item];
    }
  }
  
  NSLog(@"%@", current);
  
  completionBlock(items);
}


- (id)adapter:(ISListViewAdapter *)adapter
identifierForItem:(id)item
{
  return item;
}


- (void)adapter:(ISListViewAdapter *)adapter
itemForIdentifier:(id)identifier
completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock(identifier);
}


- (id)adapter:(ISListViewAdapter *)adapter summaryForIdentifier:(id)identifier
{
  return @" ";
}


- (NSString *)adapter:(ISListViewAdapter *)adapter sectionForIdentifier:(id)identifier
{
  NSArray *current = [self stateForIndex:self.index];
  for (NSDictionary *section in current) {
    for (NSString *i in section[kSectionItems]) {
      if ([i isEqual:identifier]) {
        return section[kSectionTitle];
      }
    }
  }
  return nil;
}


#pragma mark - ISCommonDataSource


- (NSUInteger)iteration
{
  return self.index;
}


@end
