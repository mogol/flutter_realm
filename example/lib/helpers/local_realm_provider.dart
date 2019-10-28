import 'package:convert/convert.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';

class RealmProvider extends StatefulWidget {
  final Widget Function(Realm) builder;

  const RealmProvider({Key key, this.builder}) : super(key: key);

  @override
  _RealmProviderState createState() => _InMemoryRealmProviderState();
  //_RealmProviderState createState() => _FileRealmProviderState();
  //_RealmProviderState createState() => _FileNameRealmProviderState();
  //_RealmProviderState createState() => _FileDirectoryRealmProviderState();
  //_RealmProviderState createState() => _FileDirectoryNameRealmProviderState();
  //_RealmProviderState createState() => _EncryptedFileRealmProviderState();
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
    final configuration = Configuration();
    realm = Realm.open(configuration);
  }

}

class _FileNameRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(
      fileName: 'custom_name.realm'
    );
    realm = Realm.open(configuration);
  }

}

class _FileDirectoryRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(
      fileDirectory:  'custom_dir/'
    );
    realm = Realm.open(configuration);
  }

}

class _FileDirectoryNameRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final configuration = Configuration(
      fileDirectory: 'custom_dir/sub_dir/',
      fileName: 'custom_name.realm'
    );
    realm = Realm.open(configuration);
  }

}

class _EncryptedFileRealmProviderState extends _RealmProviderState {

  @override
  void initState() {
    super.initState();
    final encryptionKey = _secureRandom(64);
    final configuration = Configuration(
      fileDirectory: 'encrypted/',
      fileName: 'secure.realm',
      encryptionKey: encryptionKey
    );
    realm = Realm.open(configuration);

    print("128 character string of hexadecimal values to decrypt realm file: " + hex.encode(encryptionKey));
  }

  static Uint8List _secureRandom(int length) {
    final values = List<int>.generate(length, (i) => Random.secure().nextInt(256));
    return Uint8List.fromList(values);
  }

}
