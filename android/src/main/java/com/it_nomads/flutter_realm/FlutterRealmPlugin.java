package com.it_nomads.flutter_realm;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.realm.Realm;
import io.realm.SyncConfiguration;
import io.realm.SyncUser;

public class FlutterRealmPlugin implements MethodCallHandler {

    private FlutterRealmPlugin(MethodChannel channel) {
        this.channel = channel;
        handlers = new ArrayList<>();
        handlers.add(new SyncUserMethodSubHandler());
    }

    public static void registerWith(Registrar registrar) {
        Realm.init(registrar.context());

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.it_nomads.com/flutter_realm");

        FlutterRealmPlugin plugin = new FlutterRealmPlugin(channel);
        channel.setMethodCallHandler(plugin);
    }

    private HashMap<String, FlutterRealm> realms = new HashMap<>();
    private final MethodChannel channel;
    private List<MethodSubHandler> handlers;

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        try {
            Map arguments = (Map) call.arguments;

            for (MethodSubHandler handler : handlers) {
                if (handler.onMethodCall(call, result)) {
                    return;
                }
            }

            switch (call.method) {
                case "initialize": {
                    onInitialize(result, arguments);
                    break;
                }
                case "reset":
                    onReset(result);
                    break;
                case "asyncOpenWithConfiguration":
                    onAsyncOpenWithConfiguration(arguments, result);
                    break;
                case "syncOpenWithConfiguration":
                    onSyncOpenWithConfiguration(arguments, result);
                    break;
                default: {
                    String realmId = (String) arguments.get("realmId");
                    FlutterRealm flutterRealm = realms.get(realmId);
                    if (flutterRealm == null) {
                        String message = "Method " + call.method + ":" + arguments.toString();
                        result.error("Realm not found", message, null);
                        return;
                    }

                    flutterRealm.onMethodCall(call, result);
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.error(e.getMessage(), e.getMessage(), e.getStackTrace().toString());
        }
    }

    private void onInitialize(Result result, Map arguments) {
        String realmId = (String) arguments.get("realmId");
        FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, arguments);
        realms.put(realmId, flutterRealm);
        result.success(null);
    }

    private void onReset(Result result) {
        for (FlutterRealm realm : realms.values()) {
            realm.reset();
        }
        realms.clear();
        result.success(null);
    }

    private void onAsyncOpenWithConfiguration(Map arguments, final Result result) {
        final String realmId = (String) arguments.get("realmId");
        final SyncConfiguration configuration = getSyncConfiguration(arguments);

        Realm.getInstanceAsync(configuration, new Realm.Callback() {
            @Override
            public void onSuccess(Realm realm) {
                FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, realm);
                realms.put(realmId, flutterRealm);
                result.success(null);
            }

            @Override
            public void onError(Throwable exception) {
                result.error(exception.getLocalizedMessage(), exception.getMessage(), exception);
            }

        });

    }

    private void onSyncOpenWithConfiguration(Map arguments, Result result) {
        String realmId = (String) arguments.get("realmId");
        SyncConfiguration configuration = getSyncConfiguration(arguments);

        FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, configuration);
        realms.put(realmId, flutterRealm);
        result.success(null);
    }

    private SyncConfiguration getSyncConfiguration(Map arguments) {
        String syncServerURL = (String) arguments.get("syncServerURL");
        boolean fullSynchronization = (boolean) arguments.get("fullSynchronization");

        assert syncServerURL != null;

        SyncConfiguration.Builder builder = SyncUser.current().createConfiguration(syncServerURL);
        if (fullSynchronization) {
            builder.fullSynchronization();
        }


        return builder.build();
    }


}
