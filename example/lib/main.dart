import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/schema.dart';
import 'app.dart';

void main() async {
  final configuration = RealmConfiguration(inMemoryIdentifier: 'mainrealm');
  final realm = await Realm.open(configuration);

  await realm.deleteAllObjects();

  for (var i = 0; i < 10; i++) {
    await realm.createObject(
        'Product', Product('$i', 'Product $i').toMap(withId: true));
  }

  runApp(MyApp(realm: realm));
}
