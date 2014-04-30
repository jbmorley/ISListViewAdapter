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

#import "ISListViewAdapterItem.h"

@interface ISListViewAdapterItem ()

@property (nonatomic, weak) ISListViewAdapter *adapter;
@property (nonatomic, strong) id<ISListViewAdapterDataSource> dataSource;
@property (nonatomic, strong) id identifier;

@end

@implementation ISListViewAdapterItem


+ (id)itemWithAdapter:(ISListViewAdapter *)adapter
           dataSource:(id<ISListViewAdapterDataSource>)dataSource
           identifier:(id)identifier
{
    return [[self alloc] initWithAdapter:adapter
                              dataSource:dataSource
                              identifier:identifier];
}


- (id)initWithAdapter:(ISListViewAdapter *)adapter
           dataSource:(id<ISListViewAdapterDataSource>)dataSource
           identifier:(id)identifier
{
  self = [super init];
  if (self) {
    self.adapter = adapter;
    self.dataSource = dataSource;
    self.identifier = identifier;
  }
  return self;
}


- (void)fetch:(ISListViewAdapterBlock)completionBlock
{
  assert(self.adapter != nil);
  assert(self.dataSource != nil);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.dataSource adapter:self.adapter
           itemForIdentifier:self.identifier
             completionBlock:completionBlock];
  });
}


- (id)fetchBlocking
{
  assert(self.adapter != nil);
  assert(self.dataSource != nil);
  __block id result = nil;
  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
  [self.dataSource adapter:self.adapter
         itemForIdentifier:self.identifier
           completionBlock:^(id item) {
                  result = item;
                  dispatch_semaphore_signal(sema);
                }];
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  return result;
}


@end
