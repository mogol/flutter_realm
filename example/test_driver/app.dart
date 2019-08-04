import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/app.dart';

void main() async {
  final configuration = RealmConfiguration(inMemoryIdentifier: 'inMemory');
  final realm = await Realm.open(configuration);

  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'reset') {
      await realm.deleteAllObjects();
      return 'ok';
    }
    return '"$message" is not implemented';
  });

  runApp(MyApp(realm: realm));
}
