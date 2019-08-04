//
//  FlutterRealm.h
//  flutter_realm
//
//  Created by German Saprykin on 4/8/19.
//

#import <Foundation/Foundation.h>

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterRealm : NSObject

- (instancetype)initWithArguments:(NSDictionary *)arguments channel:(FlutterMethodChannel *)channel identifier:(NSString *)identifier;

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
