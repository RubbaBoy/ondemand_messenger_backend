import 'dart:convert';
import 'dart:io';

import 'package:ondemand_messenger_backend/utility.dart';

Map<String, dynamic> error(HttpResponse response, int code, String message) {
  response.statusCode = code;
  return {'error': message};
}

Future<Map<String, dynamic>> getBody(HttpRequest request) async =>
    jsonDecode(await utf8.decodeStream(request) ?? '{}') as Map;

Future<HttpClientResponse> sendPost(String url, Map<String, String> headers,
    Map<String, dynamic> body) async {
  var request = await httpClient.postUrl(Uri.parse(url));
  headers.forEach(request.headers.set);
  request.add(utf8.encode(jsonEncode(body)));
  return await request.close();
}