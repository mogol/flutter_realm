import 'package:flutter/material.dart';
import 'package:flutter_realm_example/helpers/encrypted_realm_storage.dart';

import 'fetch_widget.dart';
import 'helpers/local_realm_provider.dart';
import 'helpers/encrypted_realm_provider.dart';
import 'subscription_widget.dart';
import 'sync/sync.dart';

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
            case '/fetchencrypted':
              return MaterialPageRoute(
                builder: (_) => EncryptedRealmProvider(
                  builder: (realm) => FetchWidget(
                    realm: realm,
                  ),
                  storage: EncryptedRealmStorage(
                    aes256Hex: '5870cce530afbb10cf55604bf28693921e540bd1dc75c3df8f6a9dd55c1633707b50727d9c0b0f2326469cfba08feb28fd444b5b290a39a8544ee2332eea1d4b',
                    relativePath: '/foo/encrypted.realm'
                  )
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
            case '/sync':
              return MaterialPageRoute(
                builder: (_) => SyncWidget(),
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
            title: Text('Database Fetch - In Memory'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/fetch'),
          ),
          ListTile(
            key: Key('FetchEncrypted'),
            title: Text('Database Fetch - Encrypted File'),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.of(context).pushNamed('/fetchencrypted'),
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
            onTap: () => Navigator.of(context).pushNamed('/sync'),
          ),
        ],
      ),
    );
  }
}
