package com.it_nomads.flutter_realm;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.realm.Realm;

public class FlutterRealmPlugin implements MethodCallHandler {

    private FlutterRealmPlugin(MethodChannel channel) {
        this.channel = channel;
    }

    public static void registerWith(Registrar registrar) {
        Realm.init(registrar.context());

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.it_nomads.com/flutter_realm");

        FlutterRealmPlugin plugin = new FlutterRealmPlugin(channel);
        channel.setMethodCallHandler(plugin);
    }

    private HashMap<String, FlutterRealm> realms = new HashMap<>();
    private final MethodChannel channel;

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        try {
            Map arguments = (Map) call.arguments;

            if ("initialize".equals(call.method)) {
                String realmId = (String) arguments.get("realmId");
                FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, arguments);
                realms.put(realmId, flutterRealm);
                result.success(null);
            } else if ("reset".equals(call.method)) {
                for (FlutterRealm realm : realms.values()) {
                    realm.reset();
                }
                realms.clear();
                result.success(null);
            } else {
                String realmId = (String) arguments.get("realmId");
                FlutterRealm flutterRealm = realms.get(realmId);
                if (flutterRealm == null) {
                    String message = "Method " + call.method + ":" + arguments.toString();
                    result.error("Realm not found", message, null);
                    return;
                }

                flutterRealm.onMethodCall(call, result);
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.error(e.getMessage(), e.getMessage(), e.getStackTrace().toString());
        }
    }
}
