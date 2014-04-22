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

#import "ISListViewAdapterConnector.h"
#import "ISListViewAdapterOperation.h"
#import "ISListViewAdapter.h"

@interface ISListViewAdapterConnector () {
  BOOL _initialized;
}

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) ISListViewAdapter *adapter;
@property (nonatomic) UITableViewRowAnimation animation;

@end

@implementation ISListViewAdapterConnector

+ (id)connectorWithAdapter:(ISListViewAdapter *)adapter
            collectionView:(UICollectionView *)collectionView
{
  return [[self alloc] initWithAdapter:adapter
                        collectionView:collectionView];
}

- (id)initWithAdapter:(ISListViewAdapter *)adapter
       collectionView:(UICollectionView *)collectionView
{
  self = [super init];
  if (self) {
    self.adapter = adapter;
    self.collectionView = collectionView;
    [self.adapter addAdapterObserver:self];
    _initialized = NO;
    [self reloadData];
  }
  return self;
}


+ (id)connectorWithAdapter:(ISListViewAdapter *)adapter
                 tableView:(UITableView *)tableView
{
  return [[self alloc] initWithAdapter:adapter
                             tableView:tableView];
}


- (id)initWithAdapter:(ISListViewAdapter *)adapter
           tableView:(UITableView *)tableView
{
  self = [super init];
  if (self) {
    self.adapter = adapter;
    self.tableView = tableView;
    self.animation = UITableViewRowAnimationAutomatic;
    [self.adapter addAdapterObserver:self];
    _initialized = NO;
    [self reloadData];
  }
  return self;
}


- (NSUInteger)numberOfSections
{
  return [self.adapter numberOfSections];
}


- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
  return [self.adapter numberOfItemsInSection:section];
}


- (void)reloadData
{
  if (self.collectionView) {
    [self.collectionView reloadData];
  } else if (self.tableView) {
    [self.tableView reloadData];
  }
}


- (void)ready
{
  _initialized = YES;
}


#pragma mark - ISListViewAdapterObserver


- (void)adapter:(ISListViewAdapter *)adapter
performBatchUpdates:(ISListViewAdapterChanges *)updates
    fromVersion:(NSNumber *)version
{
  if (self.incrementalUpdates) {
    if (_initialized) {
      if (self.collectionView) {
        [updates applyToCollectionView:self.collectionView];
      } else if (self.tableView) {
        [updates applyToTableView:self.tableView
                 withRowAnimation:UITableViewRowAnimationFade];
      }
    } else {
      [self reloadData];
    }
  } else {
    [self reloadData];
  }
}


@end
