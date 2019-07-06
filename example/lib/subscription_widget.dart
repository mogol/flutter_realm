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
            products: snapshot.data,
          );
        });
  }

  Future _onAdd(Product product) async {
    await realm.createObject('Product', product.toMap());
  }

  Stream<List<Product>> get _stream =>
      realm.subscribeAllObjects('Product').map<List<Product>>(
          (all) => all.cast<Map>().map(Product.fromMap).toList());
}
