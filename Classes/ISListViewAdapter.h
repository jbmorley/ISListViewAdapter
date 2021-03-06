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

#import <Foundation/Foundation.h>
#import "ISListViewAdapterDataSource.h"
#import "ISListViewAdapterObserver.h"
#import "ISListViewAdapterOperationType.h"
#import "ISListViewAdapterOperation.h"
#import "ISListViewAdapterConnector.h"
#import "ISListViewAdapterLogger.h"

@class ISListViewAdapterItem;

typedef void(^ISDBTask)();

extern NSInteger ISDBViewIndexUndefined;

extern NSString *const ISListViewAdapterInvalidSection;


@interface ISListViewAdapter : NSObject
<ISListViewAdapterLogger>
{
  
  NSMutableArray *_entries;
  dispatch_queue_t _dispatchQueue;
  id<ISListViewAdapterDataSource> _dataSource;
  
}

@property (nonatomic) BOOL debug;

+ (id)adapterWithDataSource:(id<ISListViewAdapterDataSource>)dataSource;
- (id)initWithDataSource:(id<ISListViewAdapterDataSource>)dataSource;

- (void)transitionToDataSource:(id<ISListViewAdapterDataSource>)dataSource;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

- (void)invalidate;

- (void)itemForIndexPath:(NSIndexPath *)indexPath
         completionBlock:(ISListViewAdapterBlock)completionBlock;
- (id)itemForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)titleForSection:(NSInteger)section;

- (void)addAdapterObserver:(id<ISListViewAdapterObserver>)observer;
- (void)removeObserver:(id<ISListViewAdapterObserver>)observer;

@end
