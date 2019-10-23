import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';

class RealmProvider extends StatefulWidget {
  final Widget Function(Realm) builder;

  const RealmProvider({Key key, this.builder}) : super(key: key);

  @override
  _RealmProviderState createState() => _FileRealmProviderState();
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

class _InMemoryRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(inMemoryIdentifier: Uuid().v4());
    realm = Realm.open(configuration);
  }

}

class _FileRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(fileName: 'myrealm.realm');
    realm = Realm.open(configuration);
  }

}

class _EncryptedFileRealmProviderState extends _RealmProviderState {

}
