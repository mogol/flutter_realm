import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_realm_example/schema.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'page_objects/home_page_object.dart';
import 'page_objects/products_page_object.dart';
import 'page_objects/sync_signin_page_object.dart';
import 'utilities/realm_objects_server_client.dart';

void main() {
  final uuid = Uuid();

  group('Realm Sync', () {
    String instanceLink = Platform.environment['INSTANCE_LINK'];
    if (instanceLink == null) {
      print('Set INSTANCE_LINK before launch the tests');
      exit(-1);
    }

    FlutterDriver driver;

    HomePageObject homePage;
    ProductsPageObject productsPage;
    SyncSignInPageObject signInPage;

    RealmObjectServerClient client;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      productsPage = ProductsPageObject(driver);
      homePage = HomePageObject(driver);
      signInPage = SyncSignInPageObject(driver);
    });

    String username;
    String password;

    setUp(() async {
      username = 'itu-' + uuid.v4();
      password = uuid.v4();

      client = await RealmObjectServerClient.signUp(
        url: 'https://$instanceLink',
        username: username,
        password: password,
      );

      await driver.requestData('log_out_if_needed');

      await homePage.openSync();
      await signInPage.signIn(
        username: username,
        password: password,
        instanceLink: instanceLink,
      );
    });

    tearDown(() async {
      await driver.tap(find.pageBack());
      await client.deleteUser();
      client = null;
    });

    tearDownAll(() async {
      await driver.requestData('log_out_if_needed');
      if (client != null) {
        await client.deleteUser();
      }

      driver.close();
    });

    test('subscribe with local changes', () async {
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

    test('subscribe with remote changes', () async {
      final products = ['1 iPad', '2 iPhone', '3 iMac', '4 Stand 999\$'];
      await Future.delayed(Duration(seconds: 5));

      await client
          .addProducts(products.map(((title) => Product(uuid.v4(), title))));
      await productsPage.hasProducts(products);
    });
  });
}
