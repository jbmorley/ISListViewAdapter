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

- (id)initWithTests:(ISListViewAdapterTests *)tests
{
  UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
  layout.itemSize = CGSizeMake(100.0f, 100.0f);
  layout.headerReferenceSize = CGSizeMake(0.0f, 20.0f);
  layout.minimumInteritemSpacing = 5.0f;
  layout.minimumLineSpacing = 5.0f;
  layout.sectionInset = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
  
  self = [super initWithCollectionViewLayout:layout];
  if (self) {
    self.tests = tests;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tests.delegate = self;
  self.adapter = [self.tests testAdapter];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter collectionView:self.collectionView];
  
  self.navigationItem.hidesBackButton = YES;
  
  [self.tests start];
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
  return [self.adapter titleForSection:section];
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
  
  id item = [[self.adapter itemForIndexPath:indexPath] fetchBlocking];
  
  if ([item isKindOfClass:[NSString class]]) {
    cell.backgroundColor = [UIColor cyanColor];
  } else {
    if ([item[@"color"] isEqualToString:@"Cyan"]) {
      cell.backgroundColor = [UIColor cyanColor];
    } else {
      cell.backgroundColor = [UIColor yellowColor];
    }
  }
  

  return cell;
}


#pragma mark - ISListViewAdapterDelegate


- (void)willStartTest:(NSString *)test
{
  self.title = test;
}

@end
