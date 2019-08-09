part of flutter_realm;

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
    return user == null ? null : SyncUser._fromMap(user);
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
