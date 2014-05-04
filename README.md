ISListViewAdapter
=================

Determining the correct set of updates for `UITableView` and `UICollectionView` is hard.  `ISListViewAdapter` does all this work for you, mapping a simple array of identifiers to the internal structures required for list views.  When the array of identifiers changes, it can automatically determine the additions, removals, updates and moves, which can then be applied to  `UITableView` and `UICollectionView` using the various convenience methods provided.

Installation
------------

ISListViewAdapter is available through [CocoaPods](http://cocoapods.org/):

```
platform: ios, '6.0'
pod "ISListViewAdapter", "~> 1.0"
```

Getting Started
---------------

`ISListViewAdapter` requires clients to implement both a data source and the glue to binds to the `UITableView` or `UICollectionView` instance.

### Data Source

Clients must provide a custom implementation of the `ISListViewAdapterDataSource` protocol which serves as the data model for `ISListViewAdapter`. `ISListViewAdapterDataSource` indexes items by opaque identifiers and `ISListViewAdapter` maintains a mapping between the index paths used by `UITableView` and `UICollectionView` and these identifiers.

A simple implementation of this protocol that corresponds to the example given above might look as follows. This simply exposes the contents on an `NSDictionary`:

```objc
#import <ISListViewAdapter/ISListViewAdapter.h>
#import "CustomDataSource.h"

@interface CustomDataSource ()
@property (nonatomic, strong) NSDictionary *items;
@property (nonatomic, strong) ISListViewAdapterInvalidator *invalidator;
@end

@implementation CustomDataSource

- (id)init
{
  self = [super init];
  if (self) {
    self.items =
    @{@"item_a": @{@"title": @"Title For Item A",
                   @"section": @"Section One"},
      @"item_b": @{@"title": @"Title For Item B",
                   @"section": @"Section Two"},
      @"item_c": @{@"title": @"Title For Item C",
                   @"section": @"Section One"}};
  }
  return self;
}

// Required

- (void)identifiersForAdapter:(ISListViewAdapter *)adapter completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock([self.items allKeys]);
}

- (void)adapter:(ISListViewAdapter *)adapter itemForIdentifier:(id)identifier completionBlock:(ISListViewAdapterBlock)completionBlock
{
  NSDictionary *item = self.items[identifier];
  completionBlock(item);
}

// Optional

- (id)adapter:(ISListViewAdapter *)adapter summaryForIdentifier:(id)identifier
{
  NSDictionary *item = self.items[identifier];
  return [NSString stringWithFormat:
          @"%@, %@",
          item[@"title"],
          item[@"section"]];
}

- (NSString *)adapter:(ISListViewAdapter *)adapter sectionForIdentifier:(id)identifier
{
  NSDictionary *item = self.items[identifier];
  reeturn item[@"section"];
}

// Called when the data source is added to the adapter.
// ISListViewAdapterInvalidator should be retained if it is ever necessary for
// the data source to invalidate the ISListViewAdapter.
- (void)adapter:(ISListViewAdapter *)adapter initialize:(ISListViewAdapterInvalidator *)invalidator
{
  self.invalidator = invalidator;
}

@end
```

All datasource callbacks are performed on the main run loop.  Results for long-running operations can be provided to the `ISListViewAdapter` asynchronously by means of the completion blocks. N.B. Since all callbacks are performed on the main run loop you should cross-post any long running operations to avoid blocking the UI.

Summary and section callbacks are optional:

- `adapter:summaryForIdentifier:` returns a summary object which can be compared using `isEqual` that describes the current state of the item for a given identifier. It is used by `ISListViewAdapter` to identify updates to items. If no summary is provided, it is assumed that objects are immutable and items will not be updated or reloaded.
- `adapter:sectionForIdentifier:` returns the title (assumed unique) for the section in which the item for a given identifier should be shown. Item ordering within sections corresponds to the ordering returned via. `identifiersForAdapter:completionBlock:`. Section ordering corresponds to the order in which items for a given section are seen as returned via. `identifiersForAdapter:completionBlock:`.

### Connectors and Observers

Once you have a data source, you must create an `ISListViewAdapter` instance and bind this to your list view instance.  `ISListViewAdapterConnector` provides an off-the-shelf connector between an `ISListViewAdapter` instance and table views and collection views:

```objc
#import <ISListViewAdapter/ISListViewAdapter.h>
#import "CustomTableViewController.h"
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
  NSDictionary *item = (NSDictionary *)[[self.adapter itemForIndexPath:indexPath] fetchBlocking];

  // Configure the cell using the details of the fetched item. e.g.
  cell.textLabel.text = item[@"title"];
  
  return cell;
}

@end
```

If you wish to use `ISListViewAdapter` with your own list view implementation, or process the changes in a custom way (perhaps by scrolling changed items into view, etc), you can implement the `ISListViewAdapterObserver` protocol and observe the `ISListViewAdapter` using `addAdapterObserver:` and `removeAdapterObserver:`.

```objc
- (void)adapter:(ISListViewAdapter *)adapter performBatchUpdates:(ISListViewAdapterChanges *)changes
{
  for (ISListViewAdapterOperation *operation in changes.operations) {
    // Check the type of the operation and determine the correct change...
  }
}
```

Fetching Items
--------------

`ISListViewAdapterItem` is provides a mechanism to fetch an item for a given `NSIndexPath`. Items themselves are of type `id`, allowing you to use any object internally: the example above makes use of `NSDictionary` instances as items, but this could just as well be your own custom object, `NSManagedObject`, `FCModel`, etc.

Items can be fetched both synchronously and asynchronously. Typically it is safe to fetch items synchronously (if you are using a fast mechanism such as NSDictionary for item lookup), but you may wish to use an asynchronous fetch if you are performing a fetch from a database, or some slower data source. In an extreme case, asynchronous fetches might be used to fetch items directly from the network.

### Synchronous Fetches

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = /* ... */
  
  ISListViewAdapterItem *item = [self.adapter itemForIndexPath:indexPath];
  id myItem = [item fetchBlocking];

  // Configure the cell...
  
  return cell;
}
```

### Asynchronous Fetches

`ISListViewAdapterItem fetch:` guarantees that callbacks occur on the main run loop, irrespective of the behaviour of the backing data source:

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = /* ... */
  
  __weak UITableViewCell *weakCell = cell;
  ISListViewAdapterItem *item = [self.adapter itemForIndexPath:indexPath];
  [item fetch:^(id myItem) {
    UITableViewCell *strongCell = weakCell;
    if (cell) {
    
      // Configure the cell...

      // Ensure the cell is redrawn.
      [cell setNeedsLayout];
    }
  }];

  return cell;
}
```

Performance
-----------

`ISListViewAdapter` is designed for very large data sets:

- Only the data required to determine the positions of items in the list and to calculate changes when the contents changes is fetched and maintained in-memory: items themsevles are fetched asynchronously and only when required to render the item in the UI.
- Change calculation is performed asynchronously, with each new `ISListViewAdapter` creating its own dispatch queue: updates may be slower to calculate with larger data sets, but doing so should never block the main run loop.


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

Changelog
---------

### 1.0.0

- Initial release.

License
-------

ISListViewAdapter is available under the MIT license. See the LICENSE file for more info.
