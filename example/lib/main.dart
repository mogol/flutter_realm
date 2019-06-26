import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'schema.dart';

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    if (message == 'Realm.deleteAllObjectsFromAllRealms') {
      await Realm.deleteAllObjectsFromAllRealms();
      return 'ok';
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: _Home());
}

class _Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  var _products = <Product>[];

  Realm realm;
  @override
  void initState() {
    super.initState();
    _initRealm();
  }

  _initRealm() async {
    final inMemory = RealmConfiguration(inMemoryIdentifier: 'mainrealm');
    realm = Realm();
    await realm.initialize(inMemory);
    await realm.deleteAllObjects();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (_, i) => ListTile(
              title: Text(_products[i].title),
              trailing: PopupMenuButton(
                itemBuilder: (_) => null,
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        key: Key('add'),
        child: Icon(Icons.add),
        onPressed: _onAdd(context),
      ),
    );
  }

  Function _onAdd(BuildContext context) {
    return () async {
      final _controller = TextEditingController();
      final title = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text('Enter title'),
              contentPadding: EdgeInsets.all(16),
              children: <Widget>[
                TextField(
                  key: Key('titleField'),
                  controller: _controller,
                ),
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    FlatButton(
                      key: Key('ok'),
                      child: Text('Ok'),
                      onPressed: () =>
                          Navigator.of(context).pop(_controller.text),
                    ),
                  ],
                )
              ],
            ),
      );

      if (title == null) {
        return;
      }

      final product = Product(Uuid().v4(), title);
      await realm.createObject('Product', product.toMap());

      _fetch();
    };
  }

  _fetch() async {
    final List all = await realm.allObjects('Product');

    setState(() {
      _products = all.cast<Map>().map(Product.fromMap).toList();
    });
  }
}
