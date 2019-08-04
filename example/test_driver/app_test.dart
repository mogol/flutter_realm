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
    final fetchTestFinder = find.byValueKey('Fetch');
    final subscribeTestFinder = find.byValueKey('Subscribe');

    final okFinder = find.byValueKey('ok');
    final deleteButton = find.byValueKey('Delete');
    final editButton = find.byValueKey('Edit');
    final searchButton = find.byValueKey('search');

    final titleFieldFinder = find.byValueKey('titleField');

    final rowTitleFinder = (int i) => find.byValueKey('row_${i}_title');
    final rowMenuFinder = (int i) => find.byValueKey('row_${i}_menu');

    final hasProducts = (List<String> products) async {
      for (var i = 0; i < products.length; i++) {
        await expectLater(await driver.getText(rowTitleFinder(i)), products[i]);
      }
    };
    final createProducts = (List<String> products) async {
      for (var product in products) {
        await driver.tap(addFinder);
        await driver.tap(titleFieldFinder);
        await driver.enterText(product);
        await driver.tap(okFinder);
      }
    };

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    setUp(() async {
      await driver.requestData('reset');
    });

    tearDown(() async {
      await driver.requestData('reset');
    });

    tearDownAll(() async {
      await driver.requestData('reset');

      if (driver != null) driver.close();
    });

    test('fetch', () async {
      await driver.tap(fetchTestFinder);

      final products = ['1 iPhone', '2 iPad', '3 iMac', '4 Stand 999\$'];

      await createProducts(products);

      await hasProducts(products);
    });

    test('subscribe', () async {
      await driver.tap(subscribeTestFinder);

      final products = ['1 iPad', '2 iPhone', '3 iMac', '4 Stand 999\$'];
      final updatedProducts = [
        '1 iPad Pro',
        '2 iPhone X',
        '3 Mac Pro',
        '4 Stand 007\$'
      ];

      await createProducts(products);
      await hasProducts(products);

      for (var i = 0; i < products.length; i++) {
        await driver.tap(rowMenuFinder(i));
        await driver.tap(editButton);
        await driver.tap(titleFieldFinder);
        await driver.enterText(updatedProducts[i]);
        await driver.tap(okFinder);
      }

      await hasProducts(updatedProducts);

      while (updatedProducts.isNotEmpty) {
        final product = updatedProducts.last;
        updatedProducts.removeLast();

        await driver.tap(rowMenuFinder(updatedProducts.length));
        await driver.tap(deleteButton);

        await driver.waitForAbsent(find.text(product));
      }
    });

    test('subscribe with search', () async {
      await driver.tap(subscribeTestFinder);
      final searchTerm = 'iPhone';

      final products = [
        '1 iPad',
        '2 iPhone 7',
        '3 iMac',
        '4 Stand 999\$',
        '5 iPhone 8'
      ];
      await createProducts(products);

      await driver.tap(searchButton);
      await driver.tap(titleFieldFinder);
      await driver.enterText(searchTerm);
      await driver.tap(okFinder);

      final expected = ['2 iPhone 7', '5 iPhone 8'];
      await hasProducts(expected);

      final newProducts = ['6 iMax Pro', '7 Mac Mini'];
      final newPhones = ['8 iPhone X', '9 iPhone XS'];
      await createProducts(newProducts + newPhones);

      await hasProducts(expected + newPhones);
    });
  });
}
