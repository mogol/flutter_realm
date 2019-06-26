// This is a basic Flutter Driver test for the application. A Flutter Driver
// test is an end-to-end test that "drives" your application from another
// process or even from another computer. If you are familiar with
// Selenium/WebDriver for web, Espresso for Android or UI Automation for iOS,
// this is simply Flutter's version of that.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    final addFinder = find.byValueKey('add');
    final okFinder = find.byValueKey('ok');
    final titleFieldFinder = find.byValueKey('titleField');

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      driver.requestData('Realm.deleteAllObjectsFromAllRealms');
    });

    tearDownAll(() async {
      if (driver != null) driver.close();
    });

    test('create products', () async {
      final products = ['iPhone', 'iPad', 'iMac', 'Stand 999\$'];

      for (var product in products) {
        await driver.tap(addFinder);
        await driver.tap(titleFieldFinder);
        await driver.enterText(product);
        await driver.tap(okFinder);
      }

      for (var product in products) {
        await driver.waitFor(find.text(product));
      }
    });
  });
}
