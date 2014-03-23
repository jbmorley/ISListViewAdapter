//
//  ISListViewAdapterChanges.h
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import <Foundation/Foundation.h>

@interface ISListViewAdapterSectionMove : NSObject

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger newSection;

@end

@interface ISListViewAdapterChanges : NSObject

@property (nonatomic, strong) NSMutableIndexSet *sectionDeletions;
@property (nonatomic, strong) NSMutableIndexSet *sectionInsertions;
@property (nonatomic, strong) NSMutableArray *sectionMoves;

@property (nonatomic, strong) NSMutableArray *itemDeletions;
@property (nonatomic, strong) NSMutableArray *itemInsertions;

- (void)deleteSection:(NSInteger)section;
- (void)insertSection:(NSInteger)section;
- (void)moveSection:(NSInteger)section
          toSection:(NSInteger)newSection;

- (void)applyToTableView:(UITableView *)tableView
        withRowAnimation:(UITableViewRowAnimation)animation;

@end
