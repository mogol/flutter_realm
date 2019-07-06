import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';

import 'helpers/products_widget.dart';
import 'schema.dart';

class SubscriptionWidget extends StatelessWidget {
  final Realm realm;

  const SubscriptionWidget({Key key, this.realm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
        stream: _stream,
        initialData: [],
        builder: (context, snapshot) {
          return ProductsWidget(
            onAdd: _onAdd,
            onEdit: _onEdit,
            onDelete: _onDelete,
            products: snapshot.data,
          );
        });
  }

  Future _onAdd(Product product) async {
    await realm.createObject('Product', product.toMap(withId: true));
  }

  Future _onEdit(Product product) async {
    await realm.update(
      'Product',
      primaryKey: product.uuid,
      value: product.toMap(withId: false),
    );
  }

  Future _onDelete(Product product) async {
    await realm.delete('Product', primaryKey: product.uuid);
  }

  Stream<List<Product>> get _stream =>
      realm.subscribeAllObjects('Product').map<List<Product>>((all) {
        final products = all.cast<Map>().map(Product.fromMap).toList();
        products.sort((p1, p2) => p1.title.compareTo(p2.title));
        return products;
      });
}
