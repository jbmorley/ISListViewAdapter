//
//  ISListViewAdapterChanges.h
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import <Foundation/Foundation.h>

@interface ISListViewAdapterChanges : NSObject

@property (nonatomic, strong) NSMutableIndexSet *sectionDeletions;
@property (nonatomic, strong) NSMutableIndexSet *sectionInsertions;

@end
