//
//  UINavigationController+Pops.h
//  Pods
//
//  Created by Jason Barrie Morley on 18/03/2014.
//
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Pops)

- (NSArray *)popToViewControllerOfClass:(Class)aClass
                               animated:(BOOL)animated;

@end
