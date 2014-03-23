//
//  ISSectionsDataSource.h
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ISListViewAdapter/ISListViewAdapter.h>

@interface ISSectionsDataSource : NSObject
<ISListViewAdapterDataSource>

@property (nonatomic, assign) BOOL movesSections;

@end
