package com.it_nomads.flutter_realm;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

interface MethodSubHandler {
    boolean onMethodCall(MethodCall call, MethodChannel.Result result);
}
