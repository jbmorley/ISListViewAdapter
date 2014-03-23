ISUtilities
===========

Objective-C utility classes used in various InSeven Limited libraries and projects:

- [ISNotifier](#isnotifier)
- [NSDictionary+JSON](#nsdictionaryjson)
- [NSObject+Serialize](#nsobjectserialize)
- [UIAlertView+Block](#uialertviewblock)
- [UIApplication+Activity](#uiapplicationactivity)
- [UIView+Utilities](#uiviewutilities)

Installation
------------

ISUtilities is available through [CocoaPods](http://cocoapods.org/):

```
platform: ios, '6.0'
pod "ISUtilities", "~> 1.0"
```

Classes
-------

### ISNotifier

A lightweight notificaion mechanism for observers for situations where NSNotificationCenter requires too much boiler-plate code or isn't explicit enough:


```objc
#import <ISUtilities/ISUtilities.h>
    
// Construct the notifier.
ISNotifier *notifier = [ISNotifier new];

// Add an observer.
id anObserver = [YourCustomClass new];
[notifier addObserver:anObserver];

// Notifying all observers.
[notifier notify:@selector(didUpdate:) 
      withObject:self];

// Remove the observer (optional).
[notifier removeObserver:anObserver];
```

Notes:

- Observers are added and removed with the `addObserver:` and `removeObserver:` methods.
- Observers are weakly referenced so it is not necessary to remove them when observers are released.
- Notifications are dispatched to all observers which respond to a given selector using the `notify:withObject:withObject:...` methods. 
- It is recommended that you wrap the calls to `addObserver:` and `removeObserver:` with ones which enforce a protocol to avoid adding the wrong type of class or simply failing to implement one of your observer selectors.
- ISNotifier is not thread-safe.


### NSDictionary+JSON

JSON serialization and de-serialization category for NSDictionary:

```objc
#import <ISUtilities/ISUtilities.h>

// Serialization.
NSDictionary *outDict = @{@"title": @"cheese"};
NSString *json = [outDict JSON];
NSLog(@"%@", json); // {"title": "cheese"}

// De-serialization.
NSDictionary *inDict = [NSDictionary dictionaryWithJSON:json];
NSLog(@"Title: %@", outDict[@"title"]); // Title: cheese
```


### NSObject+Serialize

Category for checking whether an NSObject can be serialized using the `writeToFile:atomically:` and `writeToURL:atomically:` methods:

```objc
#import <ISUtilities/ISUtilities.h>

// Dictionary containing safe objects.
NSDictionary *valid =
@{@"items":
  @[@"one",
    @"two",
    @"three"]};
BOOL checkValid = [valid canWriteToFile]; // YES

// Dictionary containing unsafe objects.
NSArry *invalid =
@[[YourCustomClass new],
  [YourCustomClass new]];
BOOL checkInvalid = [invalid canWriteToFile]; // NO
```

This can prove userful if it is necessary to ensure that an NSDictionary or NSArray and its contents can be safely stored to file. It works by validating that every object is an instance of `NSData`, `NSDate`, `NSNumber`, `NSString`, `NSArray`, or `NSDictionary` (as described in the documentation for `NSArray`  and `NSDictionary`).


### UIAlertView+Block

Initialize a UIAlertView with a completion block to avoid the need to conform to the `UIAlertViewDelegate` protocol and implementing `alertView:clickedButtonAtIndex:`:

```objc
#import <ISUtilities/ISUtilities.h>

// Create the UIAlertView.
UIAlertView *alertView =
[[UIAlertView alloc] initWithTitle:@"Alert"
                         message:@"Click a button..."
                 completionBlock:^(NSUInteger buttonIndex) {
                                   if (buttonIndex == 0) {
                                     // Cancel...
                                   } else if (buttonIndex == 1) {
                                     // One...
                                   } else if (buttonIndex == 2) {
                                     // Two...
                                   }
                                 }
               cancelButtonTitle:@"Cancel"
               otherButtonTitles:@"One", @"Two", nil];

// Show the alert view.
[alertView show];
```


### UIApplication+Activity

Thread-safe category for managing the UIApplication network activity indicator by simply counting calls to `beginNetworkActivity` and `endNetworkActivity`:

```objc
#import <ISUtilities/ISUtilities.h>

// Long-running task.
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
  // Begin network activity.
  [[UIApplication sharedApplication] beginNetworkActivity];

  // Do some work...
  
  // End network activity.
  [[UIApplication sharedApplication] endNetworkActivity];
});

// Another long-running task.
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
  // Begin network activity.
  [[UIApplication sharedApplication] beginNetworkActivity];

  // Do other work...
  
  // End network activity.
  [[UIApplication sharedApplication] endNetworkActivity];
});
```


### UIView+Utilities

A convenience category on UIView offering three bits of functionality:

#### containsCurrentFirstResponder

```objc
- (BOOL)containsCurrentFirstResponder
```

Returns `YES` if the UIView or any of its subviews is the current first responder, `NO` otherwise.

#### resignCurrentFirstResponder

```objc
- (BOOL)resignCurrentFirstResponder
```

Resigns the first responder for the  UIView and any of its subviews. Returns `YES` if a first responder was found and successfully resigned, `NO` otherwise.

#### hasSuperviewOfKindOfClass:

```objc
- (BOOL)hasSuperviewOfKindOfClass:(Class)aClass
```

Walks the UIView's superviews and returns `YES` if any are of kind of class `aClass`, `NO` otherwise.

License
-------

ISUtilities is available under the MIT license. See the LICENSE file for more info.