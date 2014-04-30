//
//  UINavigationController+Pops.m
//  Pods
//
//  Created by Jason Barrie Morley on 18/03/2014.
//
//

#import "UINavigationController+Pops.h"

@implementation UINavigationController (Pops)

- (NSArray *)popToViewControllerOfClass:(Class)aClass
                               animated:(BOOL)animated
{
  UIViewController *viewController = nil;
  for (int i = self.viewControllers.count - 1; i >= 0; --i) {
    if ([self.viewControllers[i] isKindOfClass:aClass]) {
      viewController = self.viewControllers[i];
      break;
    }
  }
  return [self popToViewController:viewController
                          animated:animated];
}

@end
