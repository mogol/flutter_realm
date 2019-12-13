import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';

class RealmProvider extends StatefulWidget {
  final Widget Function(Realm) builder;

  const RealmProvider({Key key, this.builder}) : super(key: key);

  @override
  //_RealmProviderState createState() => _EncryptedFileRealmProviderState();
  _RealmProviderState createState() => _FileRealmProviderState();
  //_RealmProviderState createState() => _InMemoryRealmProviderState();
}

class _RealmProviderState extends State<RealmProvider> {
  Future<Realm> realm;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Realm>(
      future: realm,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.builder(snapshot.data);
      },
    );
  }
}

class _EncryptedFileRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final encryptionKey = hex.decode('5870cce530afbb10cf55604bf28693921e540bd1dc75c3df8f6a9dd55c1633707b50727d9c0b0f2326469cfba08feb28fd444b5b290a39a8544ee2332eea1d4b');
    final configuration = Configuration(encryptionKey: encryptionKey);
    realm = Realm.open(configuration);
  }

}

class _FileRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration();
    realm = Realm.open(configuration);
  }

}

class _InMemoryRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(inMemoryIdentifier: Uuid().v4());
    realm = Realm.open(configuration);
  }

}