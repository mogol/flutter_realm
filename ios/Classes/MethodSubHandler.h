//
//  RealmPluginHandler.h
//  flutter_realm
//
//  Created by German Saprykin on 9/8/19.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MethodSubHandler <NSObject>
- (BOOL)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;
@end

NS_ASSUME_NONNULL_END
