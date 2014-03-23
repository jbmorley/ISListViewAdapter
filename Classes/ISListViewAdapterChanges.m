//
//  ISListViewAdapterChanges.m
//  Pods
//
//  Created by Jason Barrie Morley on 23/03/2014.
//
//

#import "ISListViewAdapterChanges.h"

@implementation ISListViewAdapterChanges

- (id)init
{
  self = [super init];
  if (self) {
    self.sectionDeletions = [NSMutableIndexSet indexSet];
    self.sectionInsertions = [NSMutableIndexSet indexSet];
  }
  return self;
}

@end
