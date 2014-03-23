//
//  ISViewController.m
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 22/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <ISListViewAdapter/ISListViewAdapter.h>
#import <ISUtilities/ISUtilities.h>
#import "ISViewController.h"
#import "ISRandomDataSource.h"
#import "ISTestDataSource.h"

@interface ISViewController ()

@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;
@property (nonatomic, assign) NSUInteger test;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSMutableArray *dataSources;

@end

#define ITERATIONS 25

static NSString *const kCellIdentifier = @"Cell";
static NSString *const kSourceTitle = @"title";
static NSString *const kSourceDataSource = @"dataSource";

@implementation ISViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  
  self.dataSources = [NSMutableArray arrayWithCapacity:3];

  // Static sections.
  [self.dataSources addObject:
   @{kSourceTitle: @"Sections (static)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    return dataSource;
  }()}];
  
  // Section insertions and deletions.
  [self.dataSources addObject:
   @{kSourceTitle: @"Sections (insert, delete)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = NO;
    return dataSource;
  }()}];
  
  // Section moves.
  [self.dataSources addObject:
   @{kSourceTitle: @"Sections (move)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = YES;
    return dataSource;
  }()}];
  
  // Section insertions, deletions and moves.
  [self.dataSources addObject:
   @{kSourceTitle: @"Sections (insert, delete, move)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = YES;
    dataSource.movesSections = YES;
    return dataSource;
  }()}];
  
  // Static items.
  [self.dataSources addObject:
   @{kSourceTitle: @"Items (static)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = NO;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];
  
  // Item insertions and deletions.
  [self.dataSources addObject:
   @{kSourceTitle: @"Items (insert, delete)",
     kSourceDataSource: ^(){
    ISTestDataSource *dataSource =
    [ISTestDataSource new];
    dataSource.togglesSections = NO;
    dataSource.movesSections = NO;
    dataSource.togglesItems = YES;
    dataSource.movesItems = NO;
    return dataSource;
  }()}];

  
//  // Completely random.
//  [self.dataSources addObject:
//   @{kSourceTitle: @"Random",
//     kSourceDataSource: [ISRandomDataSource new]}];
  
  self.adapter = [ISListViewAdapter adapterWithDataSource:self.dataSources[0][kSourceDataSource]];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter tableView:self.tableView];
  
  [self _reload];
}


- (void)_reload
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
    self.count++;
    self.title = [NSString stringWithFormat:
                  @"%@ - %d",
                  self.dataSources[self.test][kSourceTitle],
                  self.count];
    
    if (self.count >= ITERATIONS) {
      self.test = self.test + 1;
      self.count = 0;
      if (self.test < self.dataSources.count) {
        [self.adapter transitionToDataSource:self.dataSources[self.test][kSourceDataSource]];
      }
    } else {
      [self.adapter invalidate];
    }
    
    if (self.test < self.dataSources.count) {
      [self _reload];
    } else {
      [[[UIAlertView alloc] initWithTitle:@"PASSED" message:@"Well done!" completionBlock:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }

  });
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
