//
//  ISViewController.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 22/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISViewController.h"
#import "ISRandomDataSource.h"
#import "ISTestDataSource.h"

@interface ISViewController ()

@property (nonatomic, strong) ISListViewAdapterTests *tests;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *const kCellIdentifier = @"Cell";

@implementation ISViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  
  self.tests = [ISListViewAdapterTests new];
  self.tests.delegate = self;
  self.adapter = [self.tests testAdapter];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter tableView:self.tableView];
  self.connector.incrementalUpdates = YES;
  
  [self.tests start];
}


- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.connector ready];
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


#pragma mark - ISListViewAdapterDelegate


- (void)willStartTest:(NSString *)test
{
  self.title = test;
}


@end
