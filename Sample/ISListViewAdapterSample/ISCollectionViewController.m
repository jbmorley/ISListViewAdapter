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

#import "ISCollectionViewController.h"

@interface ISCollectionViewController ()

@property (nonatomic, strong) ISListViewAdapterTests *tests;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *const kCellIdentifier = @"Cell";
static NSString *const kHeaderIdentifier = @"Header";

@implementation ISCollectionViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tests = [ISListViewAdapterTests new];
  self.tests.delegate = self;
  self.adapter = [self.tests testAdapter];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter collectionView:self.collectionView];
  self.connector.incrementalUpdates = YES;
  
  [self.tests start];
}


- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.connector ready];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return [self.connector numberOfSections];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [self.connector numberOfItemsInSection:section];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  NSString *title = [self.adapter titleForSection:section];
  return title;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (kind == UICollectionElementKindSectionHeader) {
    UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kHeaderIdentifier forIndexPath:indexPath];
    header.backgroundColor = [UIColor magentaColor];
    return header;
  }
  return nil;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
  cell.backgroundColor = [UIColor cyanColor];
  return cell;
}


#pragma mark - ISListViewAdapterDelegate


- (void)willStartTest:(NSString *)test
{
  self.title = test;
}

@end
