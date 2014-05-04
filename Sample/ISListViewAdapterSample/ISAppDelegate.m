//
// Copyright (c) 2013-2014 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <ISUtilities/ISUtilities.h>
#import "ISAppDelegate.h"
#import "ISTableViewController.h"
#import "ISCollectionViewController.h"

typedef enum {
  
  ISTestSetNone,
  ISTestSetTableView,
  ISTestSetCollectionView,
  
} ISTestSet;

@interface ISAppDelegate ()

@property (nonatomic, assign) ISTestSet currentSet;

@end

@implementation ISAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//  [self startTest:ISTestSetTableView];
  [self startTest:ISTestSetCollectionView];
  return YES;
}


- (void)startTest:(ISTestSet)set
{
  self.currentSet = set;
  
  ISListViewAdapterTests *tests = [ISListViewAdapterTests new];
  tests.completionDelegate = self;

  UIViewController *viewController;
  if (set == ISTestSetTableView) {

    viewController = [[ISTableViewController alloc] initWithTests:tests];
    
  } else if (set == ISTestSetCollectionView) {
    
    viewController = [[ISCollectionViewController alloc] initWithTests:tests];
    
  }
 
  [self.navigationController pushViewController:viewController
                                       animated:NO];
}

- (UINavigationController *)navigationController
{
  return (UINavigationController *)self.window.rootViewController;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - ISListViewAdapterTestsCompletionDelegate

- (void)testsDidFinish:(ISListViewAdapterTests *)tests
               success:(BOOL)success
{
  
  [self.navigationController popToRootViewControllerAnimated:NO];
  
  if (self.currentSet == ISTestSetTableView) {
    [self startTest:ISTestSetCollectionView];
  } else if (self.currentSet == ISTestSetCollectionView) {
    [[[UIAlertView alloc] initWithTitle:@"PASSED" message:@"Well done!" completionBlock:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
  }
  
}

@end
