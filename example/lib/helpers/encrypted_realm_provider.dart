import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/helpers/encrypted_realm_storage.dart';

class EncryptedRealmProvider extends StatefulWidget {
  final Widget Function(Realm) builder;
  final EncryptedRealmStorage storage;

  const EncryptedRealmProvider({Key key, this.builder, this.storage}) : super(key: key);

  @override
  _EncryptedRealmProviderState createState() => _EncryptedRealmProviderState();
}

class _EncryptedRealmProviderState extends State<EncryptedRealmProvider> {
  Future<Realm> realm;

  @override
  void initState() {
    super.initState();
    widget.storage.filePath().then((String filePath) {
      setState(() {
        final configuration = Configuration(
            encryptionKey: widget.storage.encryptionKey(),
            filePath: filePath
        );
        realm = Realm.open(configuration);
      });
    });
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