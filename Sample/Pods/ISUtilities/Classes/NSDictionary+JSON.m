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

#import "NSDictionary+JSON.h"

@implementation NSDictionary (JSON)

+ (NSDictionary *)dictionaryWithJSON:(NSString *)JSON
{
  NSData *data = [JSON dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dictionary =
  [NSJSONSerialization JSONObjectWithData:data
                                  options:0
                                    error:nil];
  return dictionary;
}


- (NSString *)JSON
{
  NSData* data =
  [NSJSONSerialization dataWithJSONObject:self
                                  options:0
                                    error:nil];
  NSString* string =
  [[NSString alloc] initWithBytes:[data bytes]
                           length:[data length]
                         encoding:NSUTF8StringEncoding];
  return string;
}

@end
