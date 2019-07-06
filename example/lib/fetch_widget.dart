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
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return ProductsWidget(
      onAdd: _onAdd,
      products: _products,
    );
  }

  Future _onAdd(Product product) async {
    await widget.realm.createObject('Product', product.toMap());
    _fetch();
  }

  _fetch() async {
    final List all = await widget.realm.allObjects('Product');

    setState(() {
      _products = all.cast<Map>().map(Product.fromMap).toList();
    });
  }
}
