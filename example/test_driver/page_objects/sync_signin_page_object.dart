import 'package:flutter_driver/flutter_driver.dart';

class SyncSignInPageObject {
  final FlutterDriver driver;

  SyncSignInPageObject(this.driver);

  SerializableFinder get instanceLinkFinder => find.byValueKey('instance_link');

  SerializableFinder get usernameFinder => find.byValueKey('username');

  SerializableFinder get passwordFinder => find.byValueKey('password');

  SerializableFinder get signUpFinder => find.byValueKey('sign_up');

  SerializableFinder get signInFinder => find.byValueKey('sign_in');

  Future enterInstanceLink(String instanceLink) => _enterText(
        instanceLink,
        instanceLinkFinder,
      );

  Future enterUsername(String username) => _enterText(username, usernameFinder);

  Future enterPassword(String password) => _enterText(password, passwordFinder);

  Future _enterText(String username, SerializableFinder to) async {
    await driver.waitFor(to);
    await driver.tap(to);
    await driver.enterText(username);
  }

  Future tapSignUp() => driver.tap(signUpFinder);

  Future tapSignIn() => driver.tap(signInFinder);

  Future signUp({String username, String password, String instanceLink}) async {
    await enterInstanceLink(instanceLink);
    await enterUsername(username);
    await enterPassword(password);
    await tapSignUp();
  }

  Future signIn({String username, String password, String instanceLink}) async {
    await enterInstanceLink(instanceLink);
    await enterUsername(username);
    await enterPassword(password);
    await tapSignIn();
  }
}
