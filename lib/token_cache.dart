class TokenCache {

  final Future<String> Function() fetchToken;

  String token;
  DateTime fetched;

  TokenCache(this.fetchToken);

  Future<String> getToken() async {
    var now = DateTime.now();
    if (token == null || now.difference(fetched).inMinutes >= 30) {
      print('Fetching new token');
      token = await fetchToken();
      fetched = now;
    }

    return token;
  }
}