// This is a basic Flutter Driver test for the application. A Flutter Driver
// test is an end-to-end test that "drives" your application from another
// process or even from another computer. If you are familiar with
// Selenium/WebDriver for web, Espresso for Android or UI Automation for iOS,
// this is simply Flutter's version of that.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'page_objects/home_page_object.dart';
import 'page_objects/products_page_object.dart';

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    HomePageObject homePage;
    ProductsPageObject productsPage;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      productsPage = ProductsPageObject(driver);
      homePage = HomePageObject(driver);
    });

    setUp(() async {
      await driver.requestData('reset');
    });

    tearDown(() async {
      await driver.tap(find.pageBack());
    });

    tearDownAll(() async {
      await driver.requestData('reset');

      if (driver != null) driver.close();
    });

    test('fetch', () async {
      await driver.waitFor(homePage.fetchTestFinder);
      await driver.tap(homePage.fetchTestFinder);

      final products = ['1 iPhone', '2 iPad', '3 iMac', '4 Stand 999\$'];

      await productsPage.createProducts(products);

      await productsPage.hasProducts(products);
    });

    test('subscribe', () async {
      await driver.waitFor(homePage.subscribeTestFinder);
      await driver.tap(homePage.subscribeTestFinder);

      final products = ['1 iPad', '2 iPhone', '3 iMac', '4 Stand 999\$'];
      final updatedProducts = [
        '1 iPad Pro',
        '2 iPhone X',
        '3 Mac Pro',
        '4 Stand 007\$'
      ];

      await productsPage.createProducts(products);
      await productsPage.hasProducts(products);

      for (var i = 0; i < products.length; i++) {
        await driver.tap(productsPage.rowMenuFinder(i));
        await driver.tap(productsPage.editButton);
        await driver.tap(productsPage.titleFieldFinder);
        await driver.enterText(updatedProducts[i]);
        await driver.tap(productsPage.okFinder);
      }

      await productsPage.hasProducts(updatedProducts);

      while (updatedProducts.isNotEmpty) {
        final product = updatedProducts.last;
        updatedProducts.removeLast();

        await productsPage.deleteRow(updatedProducts.length);

        await driver.waitForAbsent(find.text(product));
      }
    });

    test('subscribe with search', () async {
      await driver.waitFor(homePage.subscribeTestFinder);
      await driver.tap(homePage.subscribeTestFinder);
      final searchTerm = 'iPhone';

      final products = [
        '1 iPad',
        '2 iPhone 7',
        '3 iMac',
        '4 Stand 999\$',
        '5 iPhone 8'
      ];
      await productsPage.createProducts(products);

      await productsPage.search(searchTerm);

      final expected = ['2 iPhone 7', '5 iPhone 8'];
      await productsPage.hasProducts(expected);

      final newProducts = ['6 iMax Pro', '7 Mac Mini'];
      final newPhones = ['8 iPhone X', '9 iPhone XS'];

      await productsPage.createProducts(newProducts + newPhones);

      await productsPage.hasProducts(expected + newPhones);
    });
  });
}
