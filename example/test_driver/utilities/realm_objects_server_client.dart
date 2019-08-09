import 'dart:convert';
import 'package:flutter_realm_example/schema.dart';
import 'package:http/http.dart' as http;

import 'package:graphql/client.dart';

class RealmObjectServerClient {
  final String url;
  final String username;
  final String password;

  String _path;
  String _accessToken;
  String _identity;
  GraphQLClient _graphQLClient;

  RealmObjectServerClient._(this.url, this.username, this.password);

  static Future<RealmObjectServerClient> signUp(
      {String url, String username, String password}) async {
    final client = RealmObjectServerClient._(url, username, password);
    await client._auth(true);
    return client;
  }

  static Future<RealmObjectServerClient> signIn(
      {String url, String username, String password}) async {
    final client = RealmObjectServerClient._(url, username, password);
    await client._auth(false);
    return client;
  }

  Future _auth(bool register) async {
    final refreshToken = await _getRefreshToken(register);
    assert(refreshToken != null);

    final accessTokenResponse = await http.post('$url/auth',
        body: jsonEncode({
          "app_id": "",
          "provider": "realm",
          "data": refreshToken,
          "path": "/~/products"
        }),
        headers: {'Content-Type': 'application/json'});
    final body = jsonDecode(accessTokenResponse.body);
    _accessToken = body['access_token']['token'];
    _path = body['access_token']['token_data']['path'];
    _identity = body['access_token']['token_data']['identity'];
    assert(_accessToken != null && _identity != null && _path != null);

    final HttpLink _httpLink = HttpLink(uri: '$url/graphql$_path');

    final AuthLink _authLink = AuthLink(getToken: () => _accessToken);

    final Link _link = _authLink.concat(_httpLink);

    _graphQLClient = GraphQLClient(
      cache: InMemoryCache(),
      link: _link,
    );
  }

  Future<String> _getRefreshToken(bool register) async {
    final refreshTokenResponse = await http.post('$url/auth',
        body: jsonEncode({
          "app_id": "",
          "provider": "password",
          "data": username,
          "user_info": {"register": register, "password": password},
        }),
        headers: {'Content-Type': 'application/json'});

    return jsonDecode(refreshTokenResponse.body)['refresh_token']['token'];
  }

  Future deleteUser() async {
    final refreshToken = await _getRefreshToken(false);
    final urlAuthUserIdentity = '$url/auth/user/$_identity';
    await http
        .delete(urlAuthUserIdentity, headers: {'authorization': refreshToken});
  }

  Future<List<Product>> allProducts() async {
    const String readProducts = r'''
    query {
      products {
        uuid
        title
      }
    }
    ''';
    final options = QueryOptions(document: readProducts);
    final results = await _graphQLClient.query(options);
    final List data = results.data['products'];
    return data.cast<Map>().map(Product.fromMap).toList();
  }

  Future addProducts(Iterable<Product> products) {
    final requests = <Future>[];

    for (Product p in products) {
      requests.add(addProduct(uuid: p.uuid, title: p.title));
    }

    return Future.wait(requests);
  }

  Future<Product> addProduct({String uuid, String title}) async {
    const String addProducts = r'''
    mutation AddProduct($uuid: String!, $title: String!) {
      result: addProduct(input: {uuid: $uuid, title: $title}) {
        uuid
        title
      }
    }''';

    final addOptions = MutationOptions(
      document: addProducts,
      variables: <String, dynamic>{
        'uuid': uuid,
        'title': title,
      },
    );
    final results = await _graphQLClient.mutate(addOptions);
    final Map data = results.data;
    return Product.fromMap(data['result']);
  }
}
