import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/main.dart' as app;

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'reset') {
      await Realm.deleteAllObjectsFromAllRealms();
      return 'ok';
    }
    return '"$message" is not implemented';
  });

  app.main();
}
