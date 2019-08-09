import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';

import 'helpers/products_widget.dart';
import 'schema.dart';

class SubscriptionWidget extends StatefulWidget {
  final Realm realm;

  const SubscriptionWidget({Key key, this.realm}) : super(key: key);

  @override
  _SubscriptionWidgetState createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends State<SubscriptionWidget> {
  Stream<List<Product>> products;
  Realm realm;

  @override
  void initState() {
    super.initState();
    realm = widget.realm;

    products =
        realm.subscribeAllObjects('Product').map<List<Product>>(_mapProduct);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
        stream: products,
        initialData: [],
        builder: (context, snapshot) {
          return ProductsWidget(
            onAdd: _onAdd,
            onEdit: _onEdit,
            onDelete: _onDelete,
            products: snapshot.data,
            onSearch: _onSearch,
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

  void _onSearch(String term) {
    Stream<List<Map>> newProducts;

    if (term == null || term.isEmpty) {
      newProducts = realm.subscribeAllObjects('Product');
    } else {
      final query = Query('Product').contains('title', term);
      newProducts = realm.subscribeObjects(query);
    }

    setState(() => products = newProducts.map<List<Product>>(_mapProduct));
  }

  List<Product> _mapProduct(List all) {
    final products = all.cast<Map>().map(Product.fromMap).toList();
    products.sort((p1, p2) => p1.title.compareTo(p2.title));
    return products;
  }
}
