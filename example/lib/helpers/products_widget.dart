import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../schema.dart';

class ProductsWidget extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAdd;
  final Function(Product) onDelete;
  final Function(Product) onEdit;

  const ProductsWidget(
      {Key key, this.products, this.onAdd, this.onDelete, this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) {
          final product = products[i];

          return ListTile(
            key: Key(product.uuid),
            title: Text(
              product.title,
              key: Key('row_${i}_title'),
            ),
            trailing: PopupMenuButton<_Actions>(
              key: Key('row_${i}_menu'),
              itemBuilder: (_) => [
                    PopupMenuItem(
                      key: Key('Delete'),
                      child: Text('Delete'),
                      value: _Actions.remove,
                    ),
                    PopupMenuItem(
                      key: Key('Edit'),
                      child: Text('Edit'),
                      value: _Actions.edit,
                    ),
                  ],
              onSelected: (action) {
                switch (action) {
                  case _Actions.remove:
                    onDelete(product);
                    break;
                  case _Actions.edit:
                    _onEdit(context, product);
                    break;
                  default:
                    throw 'Unknown action = $action';
                    break;
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: Key('add'),
        child: Icon(Icons.add),
        onPressed: _onAdd(context),
      ),
    );
  }

  void _onEdit(BuildContext context, Product product) async {
    final title = await _requestTitle(context);

    if (title == null) {
      return;
    }

    final updated = Product(product.uuid, title);
    onEdit(updated);
  }

  Function _onAdd(BuildContext context) {
    return () async {
      final title = await _requestTitle(context);

      if (title == null) {
        return;
      }

      final product = Product(Uuid().v4(), title);
      onAdd(product);
    };
  }

  Future<String> _requestTitle(BuildContext context) async {
    final _controller = TextEditingController();

    return await showDialog<String>(
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
  }
}

enum _Actions { remove, edit }
