//
//  ISCollectionViewController.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
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
  
//  NSString *item = [[self.adapter itemForIndexPath:indexPath] fetchBlocking];
//  cell.textLabel.text = item;
  cell.backgroundColor = [UIColor cyanColor];
  
  return cell;
}


#pragma mark - ISListViewAdapterDelegate


- (void)willStartTest:(NSString *)test
{
  self.title = test;
}

@end
