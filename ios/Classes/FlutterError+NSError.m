//
//  FlutterError+NSError.m
//  flutter_realm
//
//  Created by German Saprykin on 9/8/19.
//

#import "FlutterError+NSError.h"

@implementation FlutterError (NSError)

+ (FlutterError *) fromNSError:(NSError *)error {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code]
                               message:error.localizedDescription
                               details:error.userInfo];
}

@end
