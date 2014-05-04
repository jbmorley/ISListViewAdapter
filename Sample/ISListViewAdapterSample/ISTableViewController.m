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

#import "ISTableViewController.h"
#import "ISRandomDataSource.h"
#import "ISTestDataSource.h"

@interface ISTableViewController ()

@property (nonatomic, strong) ISListViewAdapterTests *tests;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *const kCellIdentifier = @"Cell";

@implementation ISTableViewController

- (id)initWithTests:(ISListViewAdapterTests *)tests
{
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.tests = tests;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  
  self.tests.delegate = self;
  self.adapter = [self.tests testAdapter];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:self.adapter tableView:self.tableView];
  
  self.navigationItem.hidesBackButton = YES;
  
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
  
  id item = [[self.adapter itemForIndexPath:indexPath] fetchBlocking];
  if ([item isKindOfClass:[NSString class]]) {
    cell.textLabel.text = item;
  } else {
    cell.textLabel.text = item[@"identifier"];
    if ([item[@"color"] isEqualToString:@"Cyan"]) {
      cell.textLabel.textColor = [UIColor cyanColor];
    } else {
      cell.textLabel.textColor = [UIColor yellowColor];
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
