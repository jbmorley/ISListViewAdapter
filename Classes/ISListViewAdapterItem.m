//
// Copyright (c) 2013 InSeven Limited.
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

#import "ISListViewAdapterItem.h"
#import "ISListViewAdapterPrivate.h"

@interface ISListViewAdapterItem ()

@property (nonatomic, weak) ISListViewAdapter *view;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) id identifier;

@end

@implementation ISListViewAdapterItem


+ (id)entryWithAdapter:(ISListViewAdapter *)adapter
              index:(NSUInteger)index
{
  return [[self alloc] initWithAdapter:adapter
                              index:index
                         identifier:nil];
}


+ (id)entryWithAdapter:(ISListViewAdapter *)adapter
              index:(NSUInteger)index
         identifier:(id)identifier
{
  return [[self alloc] initWithAdapter:adapter
                                 index:index
                            identifier:identifier];
}


- (id)initWithAdapter:(ISListViewAdapter *)view
                index:(NSUInteger)index
           identifier:(id)identifier
{
  self = [super init];
  if (self) {
    self.view = view;
    self.index = index;
    if (identifier == nil) {
      self.identifier = [self.view identifierForIndex:self.index];
    } else {
      self.identifier = identifier;
    }
  }
  return self;
}


- (void)fetch:(ISListViewAdapterBlock)completionBlock
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view itemForIdentifier:self.identifier
                      completion:^(id item) {
                        completionBlock(item);
                      }];
  });
}


- (id)fetchBlocking
{
  __block id result = nil;
  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
  [self.view itemForIdentifier:self.identifier
                    completion:^(id item) {
                      result = item;
                      dispatch_semaphore_signal(sema);
                    }];
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  return result;
}


@end
