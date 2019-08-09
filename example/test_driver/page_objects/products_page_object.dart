import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

class ProductsPageObject {
  final FlutterDriver driver;

  ProductsPageObject(this.driver);

  SerializableFinder get addFinder => find.byValueKey('add');

  SerializableFinder get okFinder => find.byValueKey('ok');
  SerializableFinder get deleteButton => find.byValueKey('Delete');
  SerializableFinder get editButton => find.byValueKey('Edit');
  SerializableFinder get searchButton => find.byValueKey('search');

  SerializableFinder get titleFieldFinder => find.byValueKey('titleField');

  SerializableFinder rowTitleFinder(int i) => find.byValueKey('row_${i}_title');
  SerializableFinder rowMenuFinder(int i) => find.byValueKey('row_${i}_menu');

  Future<void> hasProducts(List<String> products) async {
    for (var i = 0; i < products.length; i++) {
      await expectLater(await driver.getText(rowTitleFinder(i)), products[i]);
    }
  }

  Future<void> createProducts(List<String> products) async {
    for (var product in products) {
      await driver.waitFor(addFinder);
      await driver.tap(addFinder);
      await driver.tap(titleFieldFinder);
      await driver.enterText(product);
      await driver.tap(okFinder);
    }
  }

  Future search(String term) async {
    await driver.tap(searchButton);
    await driver.tap(titleFieldFinder);
    await driver.enterText(term);
    await driver.tap(okFinder);
  }

  Future deleteRow(int rowIndex) async {
    await driver.tap(rowMenuFinder(rowIndex));
    await driver.tap(deleteButton);
  }
}
