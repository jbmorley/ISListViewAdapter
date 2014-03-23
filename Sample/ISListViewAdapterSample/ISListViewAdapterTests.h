//
//  ISListViewAdapterTests.h
//  ISListViewAdapterSample
//
//  Created by Jason Barrie Morley on 23/03/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ISListViewAdapter/ISListViewAdapter.h>

extern NSString *const kSourceTitle;
extern NSString *const kSourceDataSource;

@class ISListViewAdapterTests;

@protocol ISlistViewAdapterTestsDelegate <NSObject>

- (void)willStartTest:(NSString *)test;

@end

@interface ISListViewAdapterTests : NSObject

@property (nonatomic, weak) id<ISlistViewAdapterTestsDelegate> delegate;

- (ISListViewAdapter *)testAdapter;
- (NSArray *)testDataSources;
- (void)start;

@end
