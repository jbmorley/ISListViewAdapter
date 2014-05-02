ISListViewAdapter
=================

`ISListViewAdapter` automatically determines additions, removals, updates and moves in an array of items, providing a delegate mechanim for observers wishing to act on these. Convenience bindings are provided for `UITableView` and `UICollectionView`.

Clients must provide an implementation of the `ISListViewAdapterDataSource` protocol which serves as the data model for `ISListViewAdapter`. `ISListViewAdapterDataSource` indexes items by opaque identifiers and `ISListViewAdapter` maintains a mapping between the index paths used by `UITableView` and `UICollectionView` and these identifiers.



Getting Started
---------------

`ISListViewAdapter` is relatively simple to use but, due to its generic nature, involves a little bolier-plate so have patience.  The easiest way to get started is to look at a simple example for a `UITableViewController` subclasss, `CustomTableViewController`:

```objc
#import <ISListViewAdapter/ISListViewAdapter.h>
#import "CustomDataSource.h"

@interface CustomTableViewController ()

@property (nonatomic, strong) id<ISListViewAdapterDataSource> dataSource;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

@implementation CustomTableViewController

- (void)viewDidLoad
{
  self.dataSource = [CustomDataSource new]
  self.adapter = [ISListViewAdapter adapterWithDataSource:dataSource];
  self.connector = [ISListViewAdapterConnector connectorWithAdapter:adapter
                                                          tableView:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  // Inform the connector that our view has been fully constructed and it is safe to
  // apply incremental updates to our UITableView (or UICollectionView).
  [self.connector ready];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.connector numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return [self.connector numberOfItemsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
  return [self.adapter titleForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell =
  [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                       forIndexPath:indexPath];
  CustomItem *item = (CustomItem *)[[self.adapter itemForIndexPath:indexPath] fetchBlocking];

  // Configure the cell using the details of the fetched item.
  // e.g.
  // cell.textLabel.text = item.title;
  
  return cell;
}

@end

```

### Data Source

### Updating Data


### ISListViewAdapterDataSource

### ISListViewAdapterConnector

`ISListViewAdapterConnector` provides an off-the-shelf connector between an `ISListViewAdapter` instance and table views and collection views.

### Custom Observers

Synchronous vs. Asynchronous Fetches
------------------------------------

Performance
-----------

Databases
---------

Tests
-----

ISListViewAdapter includes some fairly comprehensive soak tests which attempt to drive UITableView and UICollectionView with as varied an input as possible.

```objc
cd Sample
pod install
xcodebuild build -workspace ISListViewAdapterSample.xcworkspace -scheme ISListViewAdapterSample
```

Limitations
-----------

`ISListViewAdapter` determines changes by first identifying and applying section insertions, deletions and moves and then, only once the section changes have been applied to the list, does it attempt to update the list with ISListView

