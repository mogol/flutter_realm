import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:uuid/uuid.dart';

import 'schema.dart';

class FetchWidget extends StatefulWidget {
  final Realm realm;

  const FetchWidget({Key key, this.realm}) : super(key: key);
  @override
  _FetchWidgetState createState() => _FetchWidgetState();
}

class _FetchWidgetState extends State<FetchWidget> {
  var _products = <Product>[];

  @override
  void initState() {
    super.initState();
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
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    key: Key('titleField'),
                    controller: _controller,
                  ),
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
      await widget.realm.createObject('Product', product.toMap());

      _fetch();
    };
  }

  _fetch() async {
    final List all = await widget.realm.allObjects('Product');

    setState(() {
      _products = all.cast<Map>().map(Product.fromMap).toList();
    });
  }
}
