import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';

import 'fetch_widget.dart';
import 'subscription_widget.dart';

class MyApp extends StatelessWidget {
  final Realm realm;

  MyApp({Key key, this.realm}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Home(),
        onGenerateRoute: (settings) {
          final path = settings.name;
          switch (path) {
            case '/fetch':
              return MaterialPageRoute(
                  builder: (_) => FetchWidget(realm: realm));
              break;
            case '/subscribe':
              return MaterialPageRoute(
                  builder: (_) => SubscriptionWidget(realm: realm));
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
