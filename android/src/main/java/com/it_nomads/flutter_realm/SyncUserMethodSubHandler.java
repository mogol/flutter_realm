package com.it_nomads.flutter_realm;


import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.realm.ObjectServerError;
import io.realm.SyncCredentials;
import io.realm.SyncUser;

public class SyncUserMethodSubHandler implements MethodSubHandler {
    @Override
    public boolean onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "logInWithCredentials":
                onLogInWithCredentials((Map) call.arguments, result);
                return true;
            case "allUsers":
                onAllUsers(result);
                return true;
            case "currentUser":
                onCurrentUser(result);
                return true;
            case "logOut":
                onLogOut((Map) call.arguments, result);
                return true;
            default:
                return false;
        }
    }

    private void onLogOut(Map arguments, MethodChannel.Result result) {
        String identity = (String) arguments.get("identity");
        SyncUser user = SyncUser.all().get(identity);

        if (user == null) {
            result.error("User with identity = \"" + identity + "\" not found.", null, null);
        } else {
            user.logOut();
            result.success(null);
        }
    }

    private void onCurrentUser(MethodChannel.Result result) {
        SyncUser syncUser = SyncUser.current();

        if (syncUser == null) {
            result.success(null);
        } else {
            result.success(Collections.unmodifiableMap(userToMap(syncUser)));

        }
    }

    private void onAllUsers(MethodChannel.Result result) {
        ArrayList<Map> data = new ArrayList<>();

        for (SyncUser user : SyncUser.all().values()) {
            data.add(userToMap(user));
        }

        result.success(data);
    }

    private void onLogInWithCredentials(Map arguments, final MethodChannel.Result result) {
        SyncCredentials credentials = credentialsFromArguments(arguments);
        if (credentials == null) {
            String message = "Provider is not supported for authorization. Received: " + arguments.toString();
            result.error(message, null, null);
            return;
        }

        String url = (String) arguments.get("authServerURL");
        assert url != null;

        SyncUser.logInAsync(credentials, url, new SyncUser.Callback<SyncUser>() {
            @Override
            public void onSuccess(SyncUser user) {
                Map data = userToMap(user);
                result.success(data);
            }

            @Override
            public void onError(ObjectServerError error) {
                result.error(error.getErrorMessage(), null, null);
            }
        });

    }


    private Map userToMap(SyncUser user) {
        HashMap<String, Object> data = new HashMap<>();
        data.put("identity", user.getIdentity());
        data.put("isAdmin", user.isAdmin());

        return data;
    }

    private SyncCredentials credentialsFromArguments(Map arguments) {
        String provider = String.valueOf(arguments.get("provider"));
        Map data = (Map) arguments.get("data");
        assert data != null;

        if ("jwt".equals(provider)) {
            String jwt = (String) data.get("jwt");
            assert jwt != null;

            return SyncCredentials.jwt(jwt);
        }

        if ("username&password".equals(provider)) {
            String username = (String) data.get("username");
            String password = (String) data.get("password");
            Boolean shouldRegister = (Boolean) data.get("shouldRegister");

            return SyncCredentials.usernamePassword(username, password, shouldRegister);
        }
        return null;
    }
}
