//
//  RealmSchema.h
//  Runner
//
//  Created by German Saprykin on 5/6/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>


@interface Product : RLMObject

@property NSString *uuid;
@property NSString *title;

@end
