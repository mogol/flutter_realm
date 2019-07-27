import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/schema.dart';
import 'fetch_widget.dart';
import 'subscription_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Realm _realm;

  @override
  void initState() {
    super.initState();

    _initRealm();
  }

  Future _initRealm() async {
    final inMemory = RealmConfiguration(inMemoryIdentifier: 'mainrealm');
    _realm = Realm();

    await _realm.initialize(inMemory);
    await _realm.deleteAllObjects();

    for (var i = 0; i < 10; i++) {
      await _realm.createObject(
          'Product', Product('$i', 'Product $i').toMap(withId: true));
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Home(),
        onGenerateRoute: (settings) {
          final path = settings.name;
          switch (path) {
            case '/fetch':
              return MaterialPageRoute(
                  builder: (_) => FetchWidget(realm: _realm));
              break;
            case '/subscribe':
              return MaterialPageRoute(
                  builder: (_) => SubscriptionWidget(realm: _realm));
              break;
            default:
              print('path {$path} not found');
              return null;
              break;
          }
        },
      );
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tests'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            key: Key('Fetch'),
            title: Text('Fetch'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/fetch'),
          ),
          ListTile(
            key: Key('Subscribe'),
            title: Text('Subscribe'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/subscribe'),
          ),
        ],
      ),
    );
  }
}
