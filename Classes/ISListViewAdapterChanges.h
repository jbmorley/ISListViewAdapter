//
//  ISListViewAdapterChanges.h
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import <Foundation/Foundation.h>

//@interface ISListViewAdapterSectionMove : NSObject
//
//@property (nonatomic, assign) NSInteger section;
//@property (nonatomic, assign) NSInteger toSection;
//
//@end
//
//@interface ISListViewAdapterItemMove : NSObject;
//
//@property (nonatomic, assign) NSIndexPath *indexPath;
//@property (nonatomic, assign) NSIndexPath *toIndexPath;
//
//@end

@interface ISListViewAdapterChanges : NSObject

@property (nonatomic, strong) NSMutableArray *changes;

//@property (nonatomic, strong) NSMutableIndexSet *sectionDeletions;
//@property (nonatomic, strong) NSMutableIndexSet *sectionInsertions;
//@property (nonatomic, strong) NSMutableArray *sectionMoves;
//
//@property (nonatomic, strong) NSMutableArray *itemDeletions;
//@property (nonatomic, strong) NSMutableArray *itemInsertions;
//@property (nonatomic, strong) NSMutableArray *itemMoves;

- (void)deleteSection:(NSInteger)section;
- (void)insertSection:(NSInteger)section;
- (void)moveSection:(NSInteger)section
          toSection:(NSInteger)toSection;

- (void)deleteItem:(NSInteger)item
         inSection:(NSInteger)section;
- (void)insertItem:(NSInteger)item
         inSection:(NSInteger)section;
- (void)moveItem:(NSInteger)item
       inSection:(NSInteger)section
          toItem:(NSInteger)toItem
       inSection:(NSInteger)toSection;

- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation;
- (void)applyToCollectionView:(UICollectionView *)collectionView;

@end
