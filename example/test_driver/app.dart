import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/app.dart';
import 'package:uuid/uuid.dart';

void main() {
  // ignore: close_sinks
  final controller = StreamController<String>.broadcast();
  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'reset') {
      controller.add(null);
      return 'ok';
    }
    return '"$message" is not implemented';
  });

  runApp(TestContainer(resetStream: controller.stream));
}

class TestContainer extends StatefulWidget {
  final Stream<String> resetStream;

  const TestContainer({Key key, this.resetStream}) : super(key: key);

  @override
  _TestContainerState createState() => _TestContainerState();
}

class _TestContainerState extends State<TestContainer> {
  Future<Realm> _realm;

  @override
  void initState() {
    super.initState();

    final configuration = RealmConfiguration(inMemoryIdentifier: 'inMemory');
    _realm = Realm.open(configuration);

    final uuid = Uuid();

    widget.resetStream.listen((_) async {
      setState(() {
        final configuration = RealmConfiguration(inMemoryIdentifier: uuid.v4());
        _realm = Realm.open(configuration);
      });
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: FutureBuilder(
          future: _realm,
          builder: (_, snapshot) {
            if (snapshot.data == null) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return MyApp(
                key: ObjectKey(_realm),
                realm: snapshot.data,
              );
            }
          },
        ),
      );
}
