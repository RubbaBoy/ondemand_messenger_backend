import 'dart:convert';
import 'dart:io';

import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/utility.dart';

class Server {

  final TokenFetcher _tokenFetcher;

  Server(this._tokenFetcher);

  Future<void> start(int port) async {
    var server = await HttpServer.bind(
      '0.0.0.0',
      port,
    );

    print('Listening on ${server.address.host}:${server.port}');

    server.listen((event) async {
      var res = event.response;

      await handle(event);
      await res.close();
    });
  }

  Future<void> handle(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.write(jsonEncode({'error': 'POST Only'}));
    } else {
      var response = request.response;
      response.headers.set('Access-Control-Allow-Origin', '*');
      response.write(jsonEncode(await handleGet(request)));
      await response.close();
    }
  }

  Future<Map<String, dynamic>> handleGet(HttpRequest request) async {
    var path = request.uri.pathSegments;
    var response = request.response;

    if (path.length != 1) {
      response.statusCode = HttpStatus.methodNotAllowed;
      return {'error': 'Not Found'};
    }

    if (path[0] == 'token') {
      return {'token': await _tokenFetcher.getToken()};
    } else if (path[0] == 'sendSMS') {
      var json = jsonDecode(await utf8.decodeStream(request)) as Map;

      if (!json.containsKey('number') || !json.containsKey('message')) {
        response.statusCode = HttpStatus.badRequest;
        return {'error': 'Required number and message parameters'};
      }

      var number = parsePhoneNumber(json['number']);
      var message = json['message'];

      if (number == null || !isNumeric(number)) {
        response.statusCode = HttpStatus.badRequest;
        return {'error': 'number must be a 10 digit phone number (or longer with international code)'};
      }

      if (message.isEmpty || message.length > 4096) {
        response.statusCode = HttpStatus.badRequest;
        return {'error': 'message length must be 1-4096 characters'};
      }

      var token = await _tokenFetcher.getToken();

      var smsResponse = await sendPost('https://ondemand.rit.edu/api/communication/sendSMSReceipt', {
        'Authorization': 'Bearer $token',
        'Origin': 'https://ondemand.rit.edu',
        'Referer': 'https://ondemand.rit.edu/paymentSuccess',
        'Pragma': 'no-cache',
        'Cache-Control': 'no-cache',
        'Accept': 'application/json, text/plain',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.63',
        'Content-Type': 'application/json;charset=UTF-8',
      }, {
        'sendOrderTo': '+$number',
        'contextId': 'dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd',
        'receiptText': message
      });

      var body = await smsResponse.transform(utf8.decoder).join();

      if (smsResponse.statusCode < 200 || smsResponse.statusCode >= 300) {
        response.statusCode = HttpStatus.internalServerError;
        return {'error': 'Internal code mismatch', 'code': smsResponse.statusCode, 'response': body};
      }

      return jsonDecode(body);
    }

    response.statusCode = HttpStatus.notFound;
    return {'error': 'Not Found'};
  }

  Future<HttpClientResponse> sendPost(String url, Map<String, String> headers, Map<String, dynamic> body) async {
    var request = await httpClient.postUrl(Uri.parse(url));
    headers.forEach(request.headers.set);
    request.add(utf8.encode(jsonEncode(body)));
    return await request.close();
  }
}
