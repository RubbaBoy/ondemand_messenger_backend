class TokenCache {

  final Future<String> Function() fetchToken;

  String token;
  DateTime fetched;

  TokenCache(this.fetchToken);

  Future<String> getToken() async {
    if (token == null || fetched.difference(DateTime.now()).inMinutes >= 30) {
      print('Fetching new token');
      token = await fetchToken();
      fetched = DateTime.now();
    }

    return token;
  }
}