//
//  ISSectionsDataSource.h
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ISListViewAdapter/ISListViewAdapter.h>

@interface ISTestDataSource : NSObject
<ISListViewAdapterDataSource>

@property (nonatomic, assign) BOOL togglesSections;
@property (nonatomic, assign) BOOL movesSections;
@property (nonatomic, assign) BOOL togglesItems;
@property (nonatomic, assign) BOOL movesItems;

@end
