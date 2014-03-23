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

#import "UIView+Utilities.h"

@implementation UIView (Parent)


- (BOOL)containsCurrentFirstResponder
{
  if ([self isFirstResponder]) {
    return YES;
  }
  
  for (UIView *view in self.subviews) {
    if ([view containsCurrentFirstResponder]) {
      return YES;
    }
  }
  
  return NO;
}


- (BOOL)resignCurrentFirstResponder
{
  if ([self isFirstResponder]) {
    [self resignFirstResponder];
    return YES;
  }
  
  for (UIView *view in self.subviews) {
    if ([view resignCurrentFirstResponder]) {
      return YES;
    }
  }

  return NO;
}


- (BOOL)hasSuperviewOfKindOfClass:(Class)aClass
{
  if ([self isKindOfClass:aClass]) {
    return YES;
  } else {
    return [self.superview hasSuperviewOfKindOfClass:aClass];
  }
}

@end
