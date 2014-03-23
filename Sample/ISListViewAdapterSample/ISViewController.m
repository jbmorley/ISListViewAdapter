//
//  ISViewController.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 22/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <ISListViewAdapter/ISListViewAdapter.h>
#import "ISViewController.h"
#import "ISRandomDataSource.h"
#import "ISSectionsInsertsAndDeletesDataSource.h"

@interface ISViewController ()

@property (nonatomic, strong) id<ISListViewAdapterDataSource> dataSource;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *const kCellIdentifier = @"Cell";

@implementation ISViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  
  self.dataSource = [ISRandomDataSource new];
  self.dataSource = [ISSectionsInsertsAndDeletesDataSource new];
  self.adapter = [ISListViewAdapter adapterWithDataSource:self.dataSource];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter tableView:self.tableView];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.connector numberOfSections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.connector numberOfItemsInSection:section];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  NSString *title = [self.adapter titleForSection:section];
  return title;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
  
  NSString *item = [[self.adapter itemForIndexPath:indexPath] fetchBlocking];
  cell.textLabel.text = item;
  
  return cell;
}


@end
