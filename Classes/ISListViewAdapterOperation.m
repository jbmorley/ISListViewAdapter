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


#import "ISListViewAdapterOperation.h"

@implementation ISListViewAdapterOperation


- (NSString *)description
{
  if (self.type ==
      ISListViewAdapterOperationTypeInsertItem) {
    return [NSString stringWithFormat:
            @"insert at (%ld, %ld)",
            (long)self.indexPath.section,
            (long)self.indexPath.item];
  } else if (self.type ==
             ISListViewAdapterOperationTypeUpdateItem) {
    return [NSString stringWithFormat:
            @"update at (%ld, %ld)",
            (long)self.indexPath.section,
            (long)self.indexPath.item];
  } else if (self.type ==
             ISListViewAdapterOperationTypeMoveItem) {
    return [NSString stringWithFormat:
            @"move from (%ld, %ld) to (%ld, %ld)",
            (long)self.indexPath.section,
            (long)self.indexPath.item,
            (long)self.toIndexPath.section,
            (long)self.toIndexPath.item];
  } else if (self.type ==
             ISListViewAdapterOperationTypeDeleteItem) {
    return [NSString stringWithFormat:
            @"delete from (%ld, %ld)",
            (long)self.indexPath.section,
            (long)self.indexPath.item];
  } else if (self.type ==
             ISListViewAdapterOperationTypeInsertSection) {
    return [NSString stringWithFormat:
            @"insert section at %ld",
            (long)self.indexPath.section];
  } else if (self.type ==
             ISListViewAdapterOperationTypeDeleteSection) {
    return [NSString stringWithFormat:
            @"delete section at %ld",
            (long)self.indexPath.section];
  } else if (self.type ==
             ISListViewAdapterOperationTypeMoveSection) {
    return [NSString stringWithFormat:
            @"move section from %ld to %ld",
            (long)self.indexPath.section,
            (long)self.toIndexPath.section];
  }
  return @"";
}

@end

