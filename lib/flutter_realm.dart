library flutter_realm;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

part 'src/auth_credentials.dart';

part 'src/method_channel_transport.dart';

final _uuid = Uuid();

class SyncUser {
  final String identity;
  final bool isAdmin;

  factory SyncUser._fromMap(Map map) =>
      SyncUser._(identity: map['identity'], isAdmin: map['isAdmin']);

  SyncUser._({this.identity, this.isAdmin});

  static Future<SyncUser> logInWithCredentials({
    @required SyncCredentials credentials,
    @required String authServerURL,
  }) async {
    final user = await _realmMethodChannel.invokeMethod<Map>(
      'logInWithCredentials',
      {
        'data': credentials._data,
        'provider': credentials._provider,
        'authServerURL': authServerURL,
      },
    );

    return SyncUser._fromMap(user);
  }

  static Future<SyncUser> currentUser() async {
    final user = await _realmMethodChannel.invokeMethod<Map>('currentUser');
    return SyncUser._fromMap(user);
  }

  Future<void> logOut() =>
      _realmMethodChannel.invokeMethod('logOut', {'identity': identity});

  static Future<List<SyncUser>> allUsers() async {
    final data = await _realmMethodChannel.invokeMethod<List>('allUsers');
    final users = data.map((m) => SyncUser._fromMap(m)).toList();
    return users;
  }

  @override
  String toString() {
    return 'SyncUser{identity: $identity, isAdmin: $isAdmin}';
  }
}

class Realm {
  final _channel = MethodChannelTransport(_uuid.v4());
  final _unsubscribing = Set<String>();

  String get id => _channel.realmId;

  Realm._() {
    _channel.methodCallStream.listen(_handleMethodCall);
  }

  static Future<Realm> open(RealmConfiguration configuration) async {
    final realm = Realm._();
    await realm._invokeMethod('initialize', configuration.toMap());
    return realm;
  }

  static Future<Realm> asyncOpenWithConfiguration({
    @required String syncServerURL,
    bool fullSynchronization = false,
  }) async {
    final realm = Realm._();
    await realm._invokeMethod('asyncOpenWithConfiguration', {
      'syncServerURL': syncServerURL,
      'fullSynchronization': fullSynchronization,
    });
    return realm;
  }

  static Future<Realm> syncOpenWithConfiguration({
    @required String syncServerURL,
    bool fullSynchronization = false,
  }) async {
    final realm = Realm._();
    await realm._invokeMethod('syncOpenWithConfiguration', {
      'syncServerURL': syncServerURL,
      'fullSynchronization': fullSynchronization,
    });
    return realm;
  }

  void _handleMethodCall(MethodCall call) {
    switch (call.method) {
      case 'onResultsChange':
        final subscriptionId = call.arguments['subscriptionId'];
        if (_unsubscribing.contains(subscriptionId)) {
          return;
        }

        if (subscriptionId == null ||
            !_subscriptions.containsKey(subscriptionId)) {
          throw ('Unknown subscriptionId: [$subscriptionId]. Call: $call');
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
  }

  Future<void> deleteAllObjects() => _channel.invokeMethod('deleteAllObjects');

  static Future<void> reset() => MethodChannelTransport.reset();

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
    final subscriptionId =
        'subscribeAllObjects:' + className + ':' + _uuid.v4();

    final controller = BehaviorSubject<List<Map>>(onCancel: () {
      _unsubscribe(subscriptionId);
    });

    _subscriptions[subscriptionId] = controller;
    _invokeMethod('subscribeAllObjects', {
      '\$': className,
      'subscriptionId': subscriptionId,
    });

    return controller;
  }

  Stream<List> subscribeObjects(RealmQuery query) {
    final subscriptionId =
        'subscribeObjects:' + query.className + ':' + _uuid.v4();

    // ignore: close_sinks
    final controller = BehaviorSubject<List<Map>>(onCancel: () {
      _unsubscribe(subscriptionId);
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

  Future _unsubscribe(String subscriptionId) async {
    if (!_subscriptions.containsKey(subscriptionId)) {
      return;
    }
    _subscriptions[subscriptionId].close();
    _subscriptions.remove(subscriptionId);

    _unsubscribing.add(subscriptionId);
    await _invokeMethod('unsubscribe', {'subscriptionId': subscriptionId});
    _unsubscribing.remove(subscriptionId);
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Realm && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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

  RealmQuery contains(String field, String value) =>
      _pushThree('contains', field, value);

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
