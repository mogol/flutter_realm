import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';

import 'helpers/products_widget.dart';
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
    _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return ProductsWidget(
      onAdd: _onAdd,
      products: _products,
      onSearch: _onSearch,
      onDelete: _onDelete,
      onEdit: _onEdit,
    );
  }

  Future _onAdd(Product product) async {
    await widget.realm.createObject('Product', product.toMap(withId: true));
    _fetchAll();
  }

  void _onSearch(String term) async {
    if (term == null || term.isEmpty) {
      _fetchAll();
      return;
    }

    final query = RealmQuery('Product').contains('title', term);
    final List all = await widget.realm.objects(query);
    _updateProducts(all);
  }

  Future _onEdit(Product product) async {
    await widget.realm.update(
      'Product',
      primaryKey: product.uuid,
      value: product.toMap(withId: false),
    );
    _fetchAll();
  }

  Future _onDelete(Product product) async {
    await widget.realm.delete('Product', primaryKey: product.uuid);
    _fetchAll();
  }

  _fetchAll() async {
    final List all = await widget.realm.allObjects('Product');
    _updateProducts(all);
  }

  void _updateProducts(List all) {
    setState(() {
      _products = all.cast<Map>().map(Product.fromMap).toList();
      _products.sort((p1, p2) => p1.title.compareTo(p2.title));
    });
  }
}
