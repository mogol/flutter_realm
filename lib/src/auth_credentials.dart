part of flutter_realm;

class RealmSyncCredentials {
  RealmSyncCredentials._(this._provider, this._data);

  final String _provider;
  final Map<String, String> _data;
}

class RealmJWTAuthProvider {
  static const String providerId = 'jwt';

  static RealmSyncCredentials getCredentials({String jwt}) {
    return RealmSyncCredentials._(providerId, <String, String>{
      'jwt': jwt,
    });
  }
}
