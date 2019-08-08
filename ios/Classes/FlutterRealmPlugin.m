#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#import "FlutterRealmPlugin.h"
#import "MethodSubHandler.h"
#import "SyncUserMethodSubHandler.h"
#import "FlutterRealm.h"
#import "FlutterError+NSError.h"

static NSString *const CHANNEL_NAME = @"plugins.it_nomads.com/flutter_realm";


@interface FlutterRealmPlugin ()
@property FlutterMethodChannel *channel;
@property NSMutableDictionary<NSString *, FlutterRealm *> *realms;
@property NSArray<MethodSubHandler> *handlers;
@end


@implementation FlutterRealmPlugin

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    _channel = channel;
    _realms = [NSMutableDictionary dictionary];
    _handlers = (NSArray<MethodSubHandler> *)@[[[SyncUserMethodSubHandler alloc] init]];
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
        for (id<MethodSubHandler> handler in self.handlers){
            if ([handler handleMethodCall:call result:result]){
                return;
            }
        }
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
        } else if ([@"asyncOpenWithConfiguration" isEqualToString:method]){
            [self handleAsyncOpenWithConfiguration:arguments result:result];
        } else if ([@"syncOpenWithConfiguration" isEqualToString:method]){
            [self handleSyncOpenWithConfiguration:arguments result:result];
        }else {
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
                                        result([FlutterError fromNSError:error]);
                                    }
                                }];
}

- (void)handleSyncOpenWithConfiguration:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *realmId = arguments[@"realmId"];
    NSString *syncServerURLString = arguments[@"syncServerURL"];
    bool fullSynchronization = [arguments[@"fullSynchronization"] boolValue];
    NSURL *syncServerURL = [NSURL URLWithString: syncServerURLString];
    RLMSyncUser *user = [RLMSyncUser currentUser];
    RLMRealmConfiguration *config = [user configurationWithURL:syncServerURL fullSynchronization:fullSynchronization];
    
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    if (error != nil) {
        FlutterError *flutterError = [FlutterError fromNSError:error];
        result(flutterError);
        return;
    }
    
    FlutterRealm *flutterRealm = [[FlutterRealm alloc] initWithRealm:realm channel:self.channel identifier:realmId];
    self.realms[realmId] = flutterRealm;
    result(nil);
}

@end
