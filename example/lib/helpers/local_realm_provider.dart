import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';

class RealmProvider extends StatefulWidget {
  final Widget Function(Realm) builder;

  const RealmProvider({Key key, this.builder}) : super(key: key);

  @override
  _RealmProviderState createState() => _RealmProviderState();
}

class _RealmProviderState extends State<RealmProvider> {
  Future<Realm> realm;

  @override
  void initState() {
    super.initState();
    final configuration = RealmConfiguration(inMemoryIdentifier: Uuid().v4());
    realm = Realm.open(configuration);
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
