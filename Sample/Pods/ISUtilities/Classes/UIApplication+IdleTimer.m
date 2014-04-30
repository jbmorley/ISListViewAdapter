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

#import "UIApplication+IdleTimer.h"
#import <objc/runtime.h>

static char *const kIdleTimerCount = "is_idleTimerCount";

@implementation UIApplication (IdleTimer)


- (void)disableIdleTimer
{
  @synchronized(self) {
    self.idleTimerCount++;
    self.idleTimerDisabled = YES;
  }
}


- (void)enableIdleTimer
{
  @synchronized(self) {
    self.idleTimerCount--;
    if (self.idleTimerCount <= 0) {
      self.idleTimerDisabled = NO;
    }
  }
}


- (NSInteger)idleTimerCount
{
  NSNumber *networkActivityCount =
  objc_getAssociatedObject(self, kIdleTimerCount);
  if (networkActivityCount) {
    return [networkActivityCount integerValue];
  } else {
    return 0;
  }
}


- (void)setIdleTimerCount:(NSInteger)idleTimerCount
{
  objc_setAssociatedObject(self,
                           kIdleTimerCount,
                           @(idleTimerCount),
                           OBJC_ASSOCIATION_RETAIN);
}

@end
