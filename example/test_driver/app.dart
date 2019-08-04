import 'dart:async';

import 'package:flutter/cupertino.dart';
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
  Realm _realm;
  Uuid _uuid;

  @override
  void initState() {
    super.initState();

    _uuid = Uuid();
    reset(null);
    widget.resetStream.listen(reset);
  }

  Future reset(dynamic _) async {
    final configuration = RealmConfiguration(inMemoryIdentifier: _uuid.v4());
    final realm = await Realm.open(configuration);

    setState(() {
      _realm = realm;
    });
  }

  @override
  Widget build(BuildContext context) => MyApp(
        key: ObjectKey(_realm),
        realm: _realm,
      );
}
