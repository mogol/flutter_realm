import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

const MethodChannel _channel =
    const MethodChannel('plugins.it_nomads.com/flutter_realm');

class Realm {
  Realm() {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'onResultsChange':
          final subscriptionId = call.arguments['subscriptionId'];
          if (subscriptionId == null ||
              !_subscriptions.containsKey(subscriptionId)) {
            throw ('Unknown subscriptionId: $call');
          }
          // ignore: close_sinks
          final controller = _subscriptions[subscriptionId];
          final List results = call.arguments['results'];
          controller.value = results.cast<Map>();
          break;
        default:
          throw ('Unknown method: $call');
          break;
      }
    });
  }

  Future<void> initialize(RealmConfiguration configuration) =>
      _channel.invokeMethod('initialize', configuration.toMap());

  Future<void> deleteAllObjects() => _channel.invokeMethod('deleteAllObjects');

  static Future<void> deleteAllObjectsFromAllRealms() =>
      _channel.invokeMethod('deleteAllObjects');

  final _uuid = Uuid();

  void close() {
    final ids = _subscriptions.keys.toList();
    for (final subscriptionId in ids) {
      _unsubscribe(subscriptionId);
    }
    _subscriptions.clear();
  }

  Future<T> _invokeMethod<T>(String method, [dynamic arguments]) =>
      _channel.invokeMethod(method, arguments);

  final Map<String, BehaviorSubject<List<Map>>> _subscriptions = {};

  Future<List> allObjects(String className) =>
      _invokeMethod('allObjects', {'\$': className});

  Stream<List<Map>> subscribeAllObjects(String className) {
    final subscriptionId = className;
    if (_subscriptions.containsKey(subscriptionId)) {
      return _subscriptions[subscriptionId].stream;
    }

    final controller = BehaviorSubject<List<Map>>();

    _subscriptions[subscriptionId] = controller;
    _invokeMethod('subscribeAllObjects', {
      '\$': className,
      'subscriptionId': subscriptionId,
    });

    return controller;
  }

  Stream<List> subscribeObjects(RealmQuery query) {
    final subscriptionId = _uuid.v4();

    if (_subscriptions.containsKey(subscriptionId)) {
      return _subscriptions[subscriptionId].stream;
    }

    // ignore: close_sinks
    final controller = BehaviorSubject<List<Map>>(onCancel: () {
      _unsubscribe(subscriptionId);
      _subscriptions.remove(subscriptionId);
    });

    _subscriptions[subscriptionId] = controller;
    _invokeMethod('subscribeObjects', {
      '\$': query.className,
      'predicate': query._container,
      'subscriptionId': subscriptionId,
    });

    return controller.stream;
  }

  Future<List> objects(RealmQuery query) => _invokeMethod(
      'objects', {'\$': query.className, 'predicate': query._container});

  Future<Map> createObject(String className, Map<String, dynamic> object) =>
      _invokeMethod(
          'createObject', <String, dynamic>{'\$': className}..addAll(object));

  void _unsubscribe(String subscriptionId) {
    if (!_subscriptions.containsKey(subscriptionId)) {
      return;
    }
    _subscriptions[subscriptionId].close();
    _subscriptions.remove(subscriptionId);
    _invokeMethod('unsubscribe', {'subscriptionId': subscriptionId});
  }

  Future<Map> update(String className,
      {@required dynamic primaryKey, @required Map<String, dynamic> value}) {
    assert(value['uuid'] == null);
    return _invokeMethod('updateObject', {
      '\$': className,
      'primaryKey': primaryKey,
      'value': value,
    });
  }

  Future delete(String className, {@required dynamic primaryKey}) {
    return _invokeMethod('deleteObject', {
      '\$': className,
      'primaryKey': primaryKey,
    });
  }

  Future<String> filePath() => _invokeMethod('filePath');
}

class RealmQuery {
  final String className;

  List _container = <dynamic>[];

  RealmQuery(this.className);

  RealmQuery greaterThan(String field, dynamic value) =>
      _pushThree('greaterThan', field, value);

  RealmQuery greaterThanOrEqualTo(String field, dynamic value) =>
      _pushThree('greaterThanOrEqualTo', field, value);

  RealmQuery lessThan(String field, dynamic value) =>
      _pushThree('lessThan', field, value);

  RealmQuery lessThanOrEqualTo(String field, dynamic value) =>
      _pushThree('lessThanOrEqualTo', field, value);

  RealmQuery equalTo(String field, dynamic value) =>
      _pushThree('equalTo', field, value);

  RealmQuery notEqualTo(String field, dynamic value) =>
      _pushThree('notEqualTo', field, value);

  RealmQuery _pushThree(String operator, dynamic left, dynamic right) {
    _container.add([operator, left, right]);
    return this;
  }

  RealmQuery _pushOne(String operator) {
    _container.add([operator]);
    return this;
  }

  RealmQuery and() => this.._pushOne('and');

  RealmQuery or() => this.._pushOne('or');

  @override
  String toString() {
    return 'RealmQuery{className: $className, _container: $_container}';
  }
}

class RealmConfiguration {
  final String inMemoryIdentifier;

  const RealmConfiguration({this.inMemoryIdentifier});

  Map<String, String> toMap() => {'inMemoryIdentifier': inMemoryIdentifier};

  static const RealmConfiguration defaultConfiguration =
      const RealmConfiguration();
}
