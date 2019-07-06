import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../schema.dart';

class ProductsWidget extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAdd;
  final Function(Product) onDelete;
  const ProductsWidget({Key key, this.products, this.onAdd, this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) => ListTile(
              key: Key(products[i].uuid),
              title: Text(products[i].title),
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
                    autofocus: true,
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
      onAdd(product);
    };
  }
}
