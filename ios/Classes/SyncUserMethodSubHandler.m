//
//  FlutterSyncUser.m
//  flutter_realm
//
//  Created by German Saprykin on 9/8/19.
//

#import <Realm/Realm.h>
#import "SyncUserMethodSubHandler.h"
#import "FlutterError+NSError.h"


@interface SyncUserMethodSubHandler()
@end

@implementation SyncUserMethodSubHandler

- (BOOL)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *aSelector = [NSString stringWithFormat:@"%@:result:", call.method];
    SEL selector = NSSelectorFromString(aSelector);
    if ([self respondsToSelector:selector]){
        [self performSelector:selector withObject:call.arguments withObject:result];
        return true;
    }
    return false;
}


- (void)logInWithCredentials:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *urlString = arguments[@"authServerURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    RLMSyncCredentials *creds = [self credentialsFromArguments:arguments];
    if (creds == nil){
        NSString *message = [NSString stringWithFormat:@"Provider is nit supported for authorization. Received: %@", arguments];
        FlutterError *error =[FlutterError errorWithCode:@"-1" message:message details:nil];
        result(error);
        return;
    }
    
    [RLMSyncUser logInWithCredentials:creds authServerURL:url onCompletion:^(RLMSyncUser * _Nullable user, NSError * _Nullable error) {
        if (user != nil){
            NSMutableDictionary *map = [NSMutableDictionary dictionary];
            map[@"identity"] = user.identity;
            result(map);
        }else{
            result([FlutterError fromNSError:error]);
        }
    }];
}

- (void)allUsers:(NSDictionary *)arguments result:(FlutterResult)result {
    NSMutableArray *data = [NSMutableArray array];
    
    for (RLMSyncUser *user in [[RLMSyncUser allUsers] allValues]) {
        [data addObject:[self userToMap:user]];
    }
    result(data);
}

- (void)currentUser:(NSDictionary *)arguments result:(FlutterResult)result {
    RLMSyncUser *user = [RLMSyncUser currentUser];
    result([self userToMap:user]);
}


- (void)logOut:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *identity = arguments[@"identity"];
    RLMSyncUser *user = [RLMSyncUser allUsers][identity];
    if (user == nil) {
        NSString *message = [NSString stringWithFormat:@"User with identity \"%@\" is nil.", identity];
        FlutterError *error =[FlutterError errorWithCode:@"-1" message:message details:nil];
        result(error);
        return;
    }
    
    [user logOut];
    result(nil);
}

- (RLMSyncCredentials *)credentialsFromArguments:(NSDictionary *)arguments {
    NSString *provider = arguments[@"provider"];
    NSDictionary *data = arguments[@"data"];
    
    
    if ([@"jwt" isEqualToString:provider]){
        NSString *jwt = data[@"jwt"];
        return [RLMSyncCredentials credentialsWithJWT:jwt];
    }
    
    if ([@"username&password" isEqualToString:provider]) {
        NSString *email = data[@"username"];
        NSString *password = data[@"password"];
        BOOL shouldRegister = [data[@"shouldRegister"] boolValue];
        
        return [RLMSyncCredentials credentialsWithUsername:email password:password register:shouldRegister];
    }
    
    return nil;
}

- (NSDictionary *)userToMap:(RLMSyncUser *)user {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    map[@"identity"] = [user identity];
    map[@"isAdmin"] = @([user isAdmin]);
    map[@"refreshToken"] = [user refreshToken];
    
    return map;
}


@end
