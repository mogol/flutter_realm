//
//  FlutterError+NSError.h
//  flutter_realm
//
//  Created by German Saprykin on 9/8/19.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterError (NSError)
+ (FlutterError *) fromNSError:(NSError *)error;
@end

NS_ASSUME_NONNULL_END
