//
//  ISListViewAdapterSection.m
//  Pods
//
//  Created by Jason Barrie Morley on 22/03/2014.
//
//

#import "ISListViewAdapterSection.h"

@implementation ISListViewAdapterSection

- (id)init
{
  self = [super init];
  if (self) {
    self.items = [NSMutableArray arrayWithCapacity:3];
  }
  return self;
}


- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([self class] == [object class]) {
    ISListViewAdapterSection *section = (ISListViewAdapterSection *)object;
    return [self.title isEqual:section.title];
  }
  return NO;
}

@end
