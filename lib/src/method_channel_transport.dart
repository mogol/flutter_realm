import 'dart:async';

import 'package:flutter/services.dart';

final MethodChannel _methodChannel =
    const MethodChannel('plugins.it_nomads.com/flutter_realm')
      ..setMethodCallHandler(MethodChannelTransport._handleMethodCall);

class MethodChannelTransport {
  final String realmId;
  final MethodChannel _channel;

  MethodChannelTransport(this.realmId, [MethodChannel channel])
      : _channel = channel ?? _methodChannel;

  Stream<MethodCall> get methodCallStream =>
      _methodCallController.stream.where(_equalRealmId);

  Future<T> invokeMethod<T>(String method, [Map arguments]) =>
      _channel.invokeMethod<T>(method, _addRealmId(arguments));

  Map _addRealmId(Map arguments) {
    final map = (arguments ?? {});
    map['realmId'] = realmId;
    return map;
  }

  bool _equalRealmId(MethodCall call) => call.arguments['realmId'] == realmId;

  // ignore: close_sinks
  static final _methodCallController = StreamController<MethodCall>.broadcast();

  static Future<dynamic> _handleMethodCall(MethodCall call) {
    _methodCallController.add(call);
    return null;
  }

  static Future<void> reset() => _methodChannel.invokeMethod('reset');
}
