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

#import "UIApplication+Activity.h"
#import <objc/runtime.h>


static char *const kNetworkActivityCount = "is_networkActivityCount";

@implementation UIApplication (Activity)

- (void)beginNetworkActivity
{
  @synchronized(self) {
    self.networkActivityCount++;
    self.networkActivityIndicatorVisible = YES;
  }
}


- (void)endNetworkActivity
{
  @synchronized(self) {
    self.networkActivityCount--;
    if (self.networkActivityCount <= 0) {
      self.networkActivityIndicatorVisible = NO;
    }
  }
}


- (NSInteger)networkActivityCount
{
  NSNumber *networkActivityCount =
  objc_getAssociatedObject(self, kNetworkActivityCount);
  if (networkActivityCount) {
    return [networkActivityCount integerValue];
  } else {
    return 0;
  }
}


- (void)setNetworkActivityCount:(NSInteger)networkActivityCount
{
  objc_setAssociatedObject(self,
                           kNetworkActivityCount,
                           @(networkActivityCount),
                           OBJC_ASSOCIATION_RETAIN);
}

@end
