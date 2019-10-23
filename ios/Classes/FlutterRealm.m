//
//  FlutterRealm.m
//  flutter_realm
//
//  Created by German Saprykin on 4/8/19.
//

#import "FlutterRealm.h"

#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>

@interface FlutterRealm ()
@property (strong, nonatomic) RLMRealm *realm;
@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) NSMutableDictionary<NSString *,RLMNotificationToken *> *tokens;
@property (copy, nonatomic) NSString *realmId;

@end

@implementation RLMObject (FlutterRealm)

- (NSDictionary *)toMap {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    for (RLMProperty *p in [[self objectSchema] properties]) {
        
        if ([self[p.name] isKindOfClass:[RLMArray class]]){
            RLMArray *data = self[p.name];
            NSMutableArray *sendData = [NSMutableArray array];
            for (id item in data) {
                [sendData addObject:item];
            }
            map[p.name] = sendData;
        }else {
            map[p.name] = self[p.name];
        }
    }
    
    return map;
}

@end

@implementation FlutterRealm

- (instancetype)initWithRealm:(RLMRealm *)realm channel:(FlutterMethodChannel *)channel identifier:(NSString *)identifier {
    self = [super init];
    
    if (self != nil) {
        _realmId = identifier;
        _channel = channel;
        _tokens = [NSMutableDictionary dictionary];
        _realm = realm;
    }
    
    return self;
}

- (instancetype)initWithArguments:(NSDictionary *)arguments channel:(FlutterMethodChannel *)channel identifier:(NSString *)identifier{
    self = [super init];
    
    if (self != nil) {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        
        if ([arguments[@"inMemoryIdentifier"] isKindOfClass:[NSString class]]){
            config.inMemoryIdentifier = arguments[@"inMemoryIdentifier"];
        }

        if ([arguments[@"fileName"] isKindOfClass:[NSString class]]){
            // TODO: Allow filePath and fileName configuration
            config.fileURL = [NSURL fileURLWithPath:arguments[@"fileName"]];
        }
        
        _realmId = identifier;
        _channel = channel;
        _tokens = [NSMutableDictionary dictionary];
        _realm = [RLMRealm realmWithConfiguration:config error:nil];
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];
    NSString *method = [call method];
    @try {
        
        if ([@"createObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            if (classname == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            NSDictionary *value = [self sanitizeReceivedValue:arguments];
            [self.realm beginWriteTransaction];
            RLMObject *object = [self.realm createObject:classname withValue:value];
            [self.realm commitWriteTransaction];
            
            result([object toMap]);
        } else if ([@"allObjects" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            if (classname == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMResults *allObjects = [self.realm allObjects:classname];
            NSArray *items = [self convert:allObjects];
            result(items);
        }  else if ([@"updateObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSDictionary *value = arguments[@"value"];
            id primaryKey = arguments[@"primaryKey"];
            
            if (classname == nil || primaryKey == nil|| value == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMObject *object = [self.realm objectWithClassName:classname forPrimaryKey:primaryKey];
            if (object == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            value = [self sanitizeReceivedValue:value];
            
            [self.realm beginWriteTransaction];
            [object setValuesForKeysWithDictionary:value];
            [self.realm commitWriteTransaction];
            
            result([object toMap]);
        }   else if ([@"deleteObject" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            id primaryKey = arguments[@"primaryKey"];
            
            if (classname == nil || primaryKey == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMObject *object = [self.realm objectWithClassName:classname forPrimaryKey:primaryKey];
            if (object == nil) {
                result([self notFoundFor:call]);
                return;
            }
            
            [self.realm transactionWithBlock:^{
                [self.realm deleteObject:object];
            }];
            
            result(nil);
        } else if ([@"subscribeAllObjects" isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSString *subscriptionId = arguments[@"subscriptionId"];
            
            if (classname == nil || subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMResults *allObjects = [self.realm allObjects:classname];
            
            id subscribeResult = [self subscribe:allObjects
                                  subscriptionId:subscriptionId
                                            call:call];
            result(subscribeResult);
        } else if ([@"objects"  isEqualToString:method]) {
            
            NSString *classname = arguments[@"$"];
            NSArray *predicate = arguments[@"predicate"];
            
            if (classname == nil || predicate == nil ){
                result([self invalidParametersFor:call]);
                return;
            }
            RLMResults *results = [self.realm objects:classname withPredicate:[self generatePredicate:predicate]];
            
            NSMutableArray *items = [NSMutableArray array];
            for (RLMObject *item in results) {
                [items addObject:[item toMap]];
            }
            result(items);
        }  else if ([@"subscribeObjects"  isEqualToString:method]) {
            NSString *classname = arguments[@"$"];
            NSString *subscriptionId = arguments[@"subscriptionId"];
            NSArray *predicate = arguments[@"predicate"];
            
            if (classname == nil || predicate == nil || subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            RLMResults *results = [self.realm objects:classname withPredicate:[self generatePredicate:predicate]];
            id subscribeResult = [self subscribe:results
                                  subscriptionId:subscriptionId
                                            call:call];
            result(subscribeResult);
        } else if ([@"unsubscribe" isEqualToString:method]) {
            NSString *subscriptionId = arguments[@"subscriptionId"];
            if (subscriptionId == nil){
                result([self invalidParametersFor:call]);
                return;
            }
            
            RLMNotificationToken *token = self.tokens[subscriptionId];
            if (token == nil) {
                result([self notSubcribed:call]);
                return;
            }
            [token invalidate];
            [self.tokens removeObjectForKey:subscriptionId];
            result(nil);
        } else if ([@"deleteAllObjects" isEqualToString:method]){
            [self deleteAllObjects];
            result(nil);
        }  else if ([@"filePath" isEqualToString:method]){
            result([[self.realm.configuration fileURL] absoluteString]);
        } else {
            result(FlutterMethodNotImplemented);
        }
    } @catch (NSException *exception) {
        if ([self.realm inWriteTransaction]){
            [self.realm cancelWriteTransaction];
        }
        NSLog(@"%@", exception.callStackSymbols);
        
        result([FlutterError errorWithCode:@"-1" message:exception.reason details:[exception.userInfo description]]);
    }
}

- (void)reset {
    for (RLMNotificationToken *token in self.tokens.allValues) {
        [token invalidate];
    }
    [self.tokens removeAllObjects];
    [self deleteAllObjects];
}


- (void)deleteAllObjects {
    [self.realm beginWriteTransaction];
    [self.realm deleteAllObjects];
    [self.realm commitWriteTransaction];
}


- (NSArray *)convert:(RLMResults *)results {
    NSMutableArray *items = [NSMutableArray array];
    for (RLMObject *item in results) {
        [items addObject:[item toMap]];
    }
    return items;
}

- (FlutterError *)invalidParametersFor:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"1"
                                message:@"Invalid parameter's type"
                                details:@{
                                          @"method":call.method,
                                          @"arguments":call.arguments
                                          }
             ];
    
}
- (FlutterError *)alreadySubcribed:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"2"
                                message:@"Already subscribed"
                                details:@{
                                          @"method":call.method,
                                          @"arguments":call.arguments
                                          }
             ];
    
}

- (FlutterError *)notSubcribed:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"3"
                                message:@"Not subscribed"
                                details:@{
                                          @"method":call.method,
                                          @"arguments":call.arguments
                                          }
             ];
    
}

- (FlutterError *)notFoundFor:(FlutterMethodCall *)call{
    return  [FlutterError errorWithCode:@"4"
                                message:@"Object not found"
                                details:@{
                                          @"method":call.method,
                                          @"arguments":call.arguments
                                          }
             ];
    
}

- (id)subscribe:(RLMResults *)results subscriptionId:(NSString *) subscriptionId call:(FlutterMethodCall *)call{
    if (self.tokens[subscriptionId] != nil){
        return [self alreadySubcribed:call];
    }
    
    RLMNotificationToken *token = [results addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        [self.channel invokeMethod:@"onResultsChange" arguments:@{
                                                                  @"realmId": self.realmId, 
                                                                  @"subscriptionId": subscriptionId,
                                                                  @"results" : [self convert:results]
                                                                  }];
    }];
    
    self.tokens[subscriptionId] = token;
    
    return nil;
}

- (NSPredicate *)generatePredicate:(NSArray *) items{
    NSMutableString *format = [NSMutableString string];
    
    NSDictionary *codeToOperator = @{
                                     @"greaterThan":@">",
                                     @"greaterThanOrEqualTo":@">=",
                                     @"lessThan":@"<",
                                     @"lessThanOrEqualTo":@"<=",
                                     @"equalTo":@"==",
                                     @"notEqualTo":@"!=",
                                     @"contains":@"CONTAINS"
                                     };
    NSMutableArray *arguments = [NSMutableArray array];
    
    for (NSArray *item in items){
        NSString *code = item[0];
        if ([code isEqualToString:@"and"] || [code isEqualToString:@"or"]){
            [format appendString:code];
        }else {
            NSString *operator = codeToOperator[code];
            NSParameterAssert(operator);
            
            [format appendFormat:@"%@ %@ %%@", item[1], operator];
            [arguments addObject:item[2]];
        }
        [format appendString:@" "];
    }
    return [NSPredicate predicateWithFormat:format argumentArray:arguments];
}


- (NSDictionary *)sanitizeReceivedValue:(NSDictionary *)value {
    NSMutableDictionary *result = [value mutableCopy];
    [result removeObjectForKey:@"$"];
    for (NSString *key in value.allKeys) {
        if ([result[key] isKindOfClass:[FlutterStandardTypedData class]]){
            FlutterStandardTypedData *data = result[key];
            result[key] = [data data];
        }
    }
    return result;
}

@end
