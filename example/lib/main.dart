import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/schema.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';

void main() async {
//  final configuration = RealmConfiguration(inMemoryIdentifier: 'mainrealm');
//  final realm = await Realm.open(configuration);

  final credentials = RealmJWTAuthProvider.getCredentials(jwt: 'ADD_YOU_JWT');
  await RealmSyncUser.logInWithCredentials(
      credentials: credentials, authServerURL: 'ADD_YOU_AUTH_SERVER_URL');

  final realm = await Realm.asyncOpenWithConfiguration(
    syncServerURL: 'ADD_YOU_SYNC_SERVER_URL',
    fullSynchronization: true,
  );

  await realm.deleteAllObjects();
  final uuid = Uuid();

  for (var i = 0; i < 10; i++) {
    await realm.createObject('Product',
        Product(uuid.v4(), 'Android Product $i').toMap(withId: true));
  }

  runApp(MyApp(realm: realm));
}
