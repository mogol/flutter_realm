#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#import "FlutterRealmPlugin.h"

#import "FlutterRealm.h"

static NSString *const CHANNEL_NAME = @"plugins.it_nomads.com/flutter_realm";


@interface FlutterRealmPlugin ()
@property FlutterMethodChannel *channel;
@property NSMutableDictionary<NSString *, FlutterRealm *> *realms;
@end


@implementation FlutterRealmPlugin

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    _channel = channel;
    _realms = [NSMutableDictionary dictionary];
    return self;
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:CHANNEL_NAME
                                     binaryMessenger:[registrar messenger]];
    FlutterRealmPlugin* instance = [[FlutterRealmPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];
    NSString *method = [call method];

    @try {
      

        
        if ([@"initialize" isEqualToString:method]){
            NSString *realmId = arguments[@"realmId"];
            NSAssert([realmId isKindOfClass:[NSString class]], @"String realmId must be provided. Got: %@", realmId);
            FlutterRealm *flutterRealm = [[FlutterRealm alloc] initWithArguments:arguments channel:self.channel identifier:realmId];
            self.realms[realmId] = flutterRealm;
            
            result(nil);
        }  else if ([@"reset" isEqualToString:method]){
            for (FlutterRealm *realm in self.realms.allValues){
                [realm reset];
            }
            
            [self.realms removeAllObjects];
            
            result(nil);
        } else if ([@"logInWithCredentials" isEqualToString:method]){
            [self handleLogInWithCredentials:arguments result:result];
        }  else if ([@"asyncOpenWithConfiguration" isEqualToString:method]){
            [self handleAsyncOpenWithConfiguration:arguments result:result];
        } else {
            NSString *realmId = arguments[@"realmId"];
            NSAssert([realmId isKindOfClass:[NSString class]], @"String realmId must be provided. Got: %@", realmId);
            FlutterRealm *realm = self.realms[realmId];

            if (realm != nil){
                [realm handleMethodCall:call result:result];
            }else {
                result([FlutterError errorWithCode:@"-1" message:@"Realm not found" details:[NSString stringWithFormat:@"Method %@:%@", method, arguments]]);
            }
        }
        
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.callStackSymbols);
        result([FlutterError errorWithCode:@"-1" message:exception.reason details:[exception.userInfo description]]);
    }
}

- (void)handleAsyncOpenWithConfiguration:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *realmId = arguments[@"realmId"];
    NSString *syncServerURLString = arguments[@"syncServerURL"];
    bool fullSynchronization = [arguments[@"fullSynchronization"] boolValue];
    NSURL *syncServerURL = [NSURL URLWithString: syncServerURLString];
    RLMSyncUser *user = [RLMSyncUser currentUser];
    RLMRealmConfiguration *config = [user configurationWithURL:syncServerURL fullSynchronization:fullSynchronization];
    
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
                                    if (realm) {
                                        FlutterRealm *flutterRealm = [[FlutterRealm alloc] initWithRealm:realm channel:self.channel identifier:realmId];
                                        self.realms[realmId] = flutterRealm;
                                        result(nil);
                                    } else {
                                        result([self fromNSError:error]);
                                    }
                                }];
}

- (void)handleLogInWithCredentials:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *provider = arguments[@"provider"];
    NSDictionary *data = arguments[@"data"];

    NSString *urlString = arguments[@"authServerURL"];
    NSURL *url = [NSURL URLWithString:urlString];

    if (![@"jwt" isEqualToString:provider]){
        NSString *message = [NSString stringWithFormat:@"Only jwt provider is supported for authorization. Received: %@", provider];
        FlutterError *error =[FlutterError errorWithCode:@"-1" message:message details:nil];
        result(error);
        return;
    }
    
    NSString *jwt = data[@"jwt"];
    RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithJWT:jwt];
    
    [RLMSyncUser logInWithCredentials:creds authServerURL:url onCompletion:^(RLMSyncUser * _Nullable user, NSError * _Nullable error) {
        if (user != nil){
            NSMutableDictionary *map = [NSMutableDictionary dictionary];
            map[@"identity"] = user.identity;
            result(map);
        }else{
            result([self fromNSError:error]);
        }
    }];
}

- (FlutterError *) fromNSError:(NSError *)error {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code]
                               message:error.localizedDescription
                               details:error.userInfo];
}
@end
