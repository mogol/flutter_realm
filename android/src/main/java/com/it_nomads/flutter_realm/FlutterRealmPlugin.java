package com.it_nomads.flutter_realm;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.realm.ObjectServerError;
import io.realm.Realm;
import io.realm.SyncConfiguration;
import io.realm.SyncCredentials;
import io.realm.SyncUser;

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
            } else if ("logInWithCredentials".equals(call.method)) {
                handleLogInWithCredentials(arguments, result);
            } else if ("asyncOpenWithConfiguration".equals(call.method)) {
                handleAsyncOpenWithConfiguration(arguments, result);
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

    private void handleAsyncOpenWithConfiguration(Map arguments, Result result) {
        String realmId = (String) arguments.get("realmId");
        String syncServerURL = (String) arguments.get("syncServerURL");
        boolean fullSynchronization = (boolean) arguments.get("fullSynchronization");

        assert syncServerURL != null;

        SyncConfiguration.Builder builder = SyncUser.current().createConfiguration(syncServerURL);
        if (fullSynchronization) {
            builder.fullSynchronization();
        }

        SyncConfiguration configuration = builder.build();

        FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, configuration);
        realms.put(realmId, flutterRealm);
        result.success(null);
    }

    private void handleLogInWithCredentials(Map arguments, final Result result) {
        String provider = String.valueOf(arguments.get("provider"));
        if (!provider.equals("jwt")) {
            result.error("Only jwt provider is supported for authorization. Received: " + provider, null, null);
            return;
        }

        Map data = (Map) arguments.get("data");
        assert data != null;

        String url = (String) arguments.get("authServerURL");
        assert url != null;


        String jwt = (String) data.get("jwt");
        assert jwt != null;

        SyncCredentials credentials = SyncCredentials.jwt(jwt);
        SyncUser.logInAsync(credentials, url, new SyncUser.Callback<SyncUser>() {
            @Override
            public void onSuccess(SyncUser user) {
                HashMap<String, String> data = new HashMap<>();
                data.put("identity", user.getIdentity());
                result.success(data);
            }

            @Override
            public void onError(ObjectServerError error) {
                result.error(error.getErrorMessage(), null, null);
            }
        });
    }
}
