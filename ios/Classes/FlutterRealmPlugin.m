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
@end
