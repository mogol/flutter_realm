import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/app.dart';

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'log_out_if_needed') {
      final users = await SyncUser.allUsers();
      for (SyncUser user in users) {
        await user.logOut();
      }
      return 'ok';
    }
    return '"$message" is not implemented';
  });

  runApp(MyApp());
}
