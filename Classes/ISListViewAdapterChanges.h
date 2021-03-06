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
#import "ISListViewAdapterLogger.h"

@class ISListViewAdapter;

@interface ISListViewAdapterChanges : NSObject

@property (nonatomic, strong) NSMutableArray *operations;

+ (id)changesWithLogger:(id<ISListViewAdapterLogger>)logger;

- (id)initWithLogger:(id<ISListViewAdapterLogger>)logger;

- (void)deleteSection:(NSInteger)section;
- (void)insertSection:(NSInteger)section;
- (void)moveSection:(NSInteger)section
          toSection:(NSInteger)toSection;

- (void)deleteItem:(NSInteger)item
         inSection:(NSInteger)section;
- (void)insertItem:(NSInteger)item
         inSection:(NSInteger)section;
- (void)moveItem:(NSInteger)item
       inSection:(NSInteger)section
          toItem:(NSInteger)toItem
       inSection:(NSInteger)toSection;

- (void)updateItem:(NSInteger)item
         inSection:(NSInteger)section;

- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation;
- (void)applyToCollectionView:(UICollectionView *)collectionView;

- (BOOL)empty;

@end
