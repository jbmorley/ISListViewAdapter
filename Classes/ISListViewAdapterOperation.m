//
// Copyright (c) 2013 InSeven Limited.
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

#import "ISListViewAdapterOperation.h"

@implementation ISListViewAdapterOperation


- (NSString *)description
{
  if (self.type == ISListViewAdapterOperationTypeInsert) {
    return [NSString stringWithFormat:
            @"insert at %d",
            self.currentIndex.item];
  } else if (self.type == ISListViewAdapterOperationTypeUpdate) {
    return [NSString stringWithFormat:
            @"update at %d",
            self.currentIndex.item];
  } else if (self.type == ISListViewAdapterOperationTypeMove) {
    return [NSString stringWithFormat:
            @"move from %d to %d",
            self.previousIndex.item,
            self.currentIndex.item];
  } else if (self.type == ISListViewAdapterOperationTypeDelete) {
    return [NSString stringWithFormat:
            @"delete from %d",
            self.previousIndex.item];
  }
  return @"";
}

@end

