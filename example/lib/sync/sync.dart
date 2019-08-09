import 'package:flutter/material.dart';
import 'package:flutter_realm/flutter_realm.dart';
import 'package:flutter_realm_example/subscription_widget.dart';

class SyncWidget extends StatefulWidget {
  @override
  _SyncWidgetState createState() => _SyncWidgetState();
}

class _SyncWidgetState extends State<SyncWidget> {
  Realm _realm;

  @override
  Widget build(BuildContext context) {
    return _realm == null
        ? Scaffold(
            appBar: AppBar(
              title: Text('Realm Sync Platform'),
            ),
            body: _SignIn(onRealm: (realm) => setState(() => _realm = realm)))
        : SubscriptionWidget(realm: _realm);
  }

  @override
  void dispose() {
    _realm?.close();

    super.dispose();
  }
}

class _SignIn extends StatefulWidget {
  final Function(Realm realm) onRealm;

  const _SignIn({Key key, @required this.onRealm}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  final form = GlobalKey<FormState>();

  String serverUrl;
  String username;
  String password;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          TextFormField(
            key: Key('instance_link'),
            initialValue: 'development-flutter-plugin.de1a.cloud.realm.io',
            decoration: InputDecoration(labelText: 'Instance link'),
            validator: (text) {
              if (text.startsWith('http') || text.startsWith('realm')) {
                return 'Enter server host without http(s)/realm';
              }
              return null;
            },
            onSaved: (text) => serverUrl = text,
          ),
          TextFormField(
            key: Key('username'),
            decoration: InputDecoration(labelText: 'Username'),
            onSaved: (text) => username = text,
          ),
          TextFormField(
            key: Key('password'),
            decoration: InputDecoration(labelText: 'Password'),
            onSaved: (text) => password = text,
          ),
          RaisedButton(
            key: Key('sign_up'),
            child: Text('Sign Up'),
            onPressed: () => _onSignIn(true),
          ),
          RaisedButton(
            key: Key('sign_in'),
            child: Text('Sign In'),
            onPressed: () => _onSignIn(false),
          ),
        ],
      ),
    );
  }

  Future<void> _onSignIn(bool shouldRegister) async {
    if (!form.currentState.validate()) {
      return;
    }
    form.currentState.save();
    final authUrl = 'https://$serverUrl';
    final syncServerUrl = 'realms://$serverUrl/~/products';

    final creds = UsernamePasswordAuthProvider.getCredentials(
      username: username,
      password: password,
      shouldRegister: shouldRegister,
    );

    try {
      await SyncUser.logInWithCredentials(
        credentials: creds,
        authServerURL: authUrl,
      );

      final realm = await Realm.asyncOpenWithConfiguration(
        syncServerURL: syncServerUrl,
        fullSynchronization: true,
      );

      widget.onRealm(realm);
    } catch (ex) {
      final bar = SnackBar(content: Text(ex.toString()));
      Scaffold.of(context).showSnackBar(bar);
    }
  }
}
