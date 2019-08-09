import 'package:flutter_driver/flutter_driver.dart';

class HomePageObject {
  final FlutterDriver driver;
  HomePageObject(this.driver);

  SerializableFinder get fetchTestFinder => find.byValueKey('Fetch');
  SerializableFinder get subscribeTestFinder => find.byValueKey('Subscribe');
  SerializableFinder get syncTestFinder => find.byValueKey('Sync');

  Future openFetch() => driver.tap(fetchTestFinder);
  Future openSubscription() => driver.tap(subscribeTestFinder);
  Future openSync() => driver.tap(syncTestFinder);
}
