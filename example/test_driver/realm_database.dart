import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_realm_example/app.dart';

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    return '"$message" is not implemented';
  });

  runApp(MyApp());
}
