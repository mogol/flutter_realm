import 'package:flutter/material.dart';

import 'fetch_widget.dart';
import 'helpers/local_realm_provider.dart';
import 'subscription_widget.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Home(),
        onGenerateRoute: (settings) {
          final path = settings.name;
          switch (path) {
            case '/fetch':
              return MaterialPageRoute(
                builder: (_) => RealmProvider(
                  builder: (realm) => FetchWidget(
                    realm: realm,
                  ),
                ),
              );
              break;
            case '/subscribe':
              return MaterialPageRoute(
                builder: (_) => RealmProvider(
                  builder: (realm) => SubscriptionWidget(
                    realm: realm,
                  ),
                ),
              );
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
            title: Text('Database Fetch'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/fetch'),
          ),
          ListTile(
            key: Key('Subscribe'),
            title: Text('Database Subscribe'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/subscribe'),
          ),
          ListTile(
            key: Key('Sync'),
            title: Text('Sync Platform'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => null,
          ),
        ],
      ),
    );
  }
}
