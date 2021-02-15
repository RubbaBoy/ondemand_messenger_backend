import 'package:ondemand_messenger_backend/token_cache.dart';

import 'utility.dart';

class TokenFetcher {

  TokenCache _tokenCache;

  TokenFetcher() {
    _tokenCache = TokenCache(_getToken);
  }

  Future<String> _getToken() async {
    var request = await httpClient.putUrl(Uri.parse('https://ondemand.rit.edu/api/login/anonymous/1312'));
    var response = await request.close();
    return response.headers['access-token']?.elementAt(0);
  }

  Future<String> getToken() async => _tokenCache.getToken();
}
