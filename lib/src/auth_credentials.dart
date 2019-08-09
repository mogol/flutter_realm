part of flutter_realm;

class SyncCredentials {
  SyncCredentials._(this._provider, this._data);

  final String _provider;
  final Map<String, dynamic> _data;
}

abstract class JWTAuthProvider {
  static const String providerId = 'jwt';

  static SyncCredentials getCredentials({String jwt}) {
    return SyncCredentials._(providerId, <String, String>{
      'jwt': jwt,
    });
  }
}

abstract class UsernamePasswordAuthProvider {
  static const String providerId = 'username&password';

  static SyncCredentials getCredentials(
      {String username, String password, bool shouldRegister = true}) {
    return SyncCredentials._(providerId, <String, dynamic>{
      'username': username,
      'password': password,
      'shouldRegister': shouldRegister,
    });
  }
}
