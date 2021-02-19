import 'dart:convert';
import 'dart:io';

import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/utility.dart';

class Server {
  final TokenFetcher _tokenFetcher;
  final BookManager _bookManager;
  final MySqlConnection _conn;

  Server(this._tokenFetcher, this._bookManager, this._conn);

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

    var res = ({
      'token': getToken,
      'sendSMS': (re, rs) => ensureParameters(request, response, sendSMS, requestParams: ['number', 'message']),
      'add': add,
      'createBook': (re, rs) => ensureParameters(request, response, createBook, requestParams: ['name', 'password']),
      'getBook': (re, rs) => ensureParameters(re, rs, getBook, bookRequest: true),
      'addNumber': (re, rs) => ensureParameters(re, rs, addNumber, bookRequest: true, requestParams: ['numberName', 'number']),
      'removeNumber': (re, rs) => ensureParameters(re, rs, removeNumber, bookRequest: true, requestParams: ['numberId']),
    })[path[0]]
        ?.call(request, response);

    if (res != null) {
      return await res;
    }

    response.statusCode = HttpStatus.notFound;
    return {'error': 'Not Found'};
  }

  Future<Map<String, dynamic>> getToken(
      HttpRequest request, HttpResponse response) async {
    return {'token': await _tokenFetcher.getToken()};
  }

  Future<Map<String, dynamic>> sendSMS(
      HttpRequest request, HttpResponse response, Map<String, dynamic> json, {String number, String message}) async {
    number = parsePhoneNumber(number);

    if (number == null || !isNumeric(number)) {
      return error(response, HttpStatus.badRequest, 'number must be a 10 digit phone number (or longer with international code)');
    }

    if (message.isEmpty || message.length > 4096) {
      return error(response, HttpStatus.badRequest, 'message length must be 1-4096 characters');
    }

    var token = await _tokenFetcher.getToken();

    var smsResponse = await sendPost(
        'https://ondemand.rit.edu/api/communication/sendSMSReceipt', {
      'Authorization': 'Bearer $token',
      'Origin': 'https://ondemand.rit.edu',
      'Referer': 'https://ondemand.rit.edu/paymentSuccess',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'Accept': 'application/json, text/plain',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.63',
      'Content-Type': 'application/json;charset=UTF-8',
    }, {
      'sendOrderTo': '+$number',
      'contextId': 'dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd',
      'receiptText': message
    });

    var body = await smsResponse.transform(utf8.decoder).join();

    if (smsResponse.statusCode < 200 || smsResponse.statusCode >= 300) {
      response.statusCode = HttpStatus.internalServerError;
      return {
        'error': 'Internal code mismatch',
        'code': smsResponse.statusCode,
        'response': body
      };
    }

    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> add(
      HttpRequest request, HttpResponse response) async {
    await _conn.query('UPDATE temp SET val = val + 1');
    var res = await await _conn.query('SELECT val FROM temp');
    var first = res.first;
    var val = first['val'];
    print('val = $val');
    return {'value': val};
  }

  Future<Map<String, dynamic>> createBook(
      HttpRequest request, HttpResponse response, Map<String, dynamic> json, {String name, String password}) async {

    if (_bookManager.containsBook(name)) {
      return error(response, HttpStatus.badRequest, 'Book with name already exists');
    }

    var book = await _bookManager.addBook(name, password);

    return {
      'book': {'id': book.bookId, 'name': book.name}
    };
  }

  Future<Map<String, dynamic>> getBook(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book) async {
    return {
      'numbers': _bookManager.getNumbers(book).map((e) => e.toJson()).toList()
    };
  }

  Future<Map<String, dynamic>> addNumber(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book, {String numberName, String number}) async {
    number = parsePhoneNumber(number);

    if (number == null || !isNumeric(number)) {
      return error(response, HttpStatus.badRequest, 'number must be a 10 digit phone number (or longer with international code)');
    }

    var addedNumber = await _bookManager.addNumber(numberName, number, book);
    return {'number': addedNumber.toJson()};
  }

  Future<Map<String, dynamic>> removeNumber(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book, {int numberId}) async {

    await _bookManager.removeNumber(numberId);
    return {};
  }

  Future<Map<String, dynamic>> ensureParameters(HttpRequest request,
      HttpResponse response, Function callback,
      {List<String> requestParams = const [], bool bookRequest = false}) async {
    var json = await getBody(request);

    var testingParams = [
      ...requestParams,
      if (bookRequest) ...['name', 'password']
    ];

    if (testingParams.any((element) => !json.containsKey(element))) {
      return error(response, HttpStatus.badRequest, 'Required parameters: ${testingParams.join(', ')}');
    }

    Book book;
    if (bookRequest) {
      var name = json['name'];
      var password = json['password'];

      book = _bookManager.getBook(name, password);
      if (book == null) {
        return error(response, HttpStatus.badRequest, 'No book could be found with the given name and password');
      }
    }

    return Function.apply(callback, [
      request,
      response,
      json,
      if (book != null)
        book
    ], {
      for (var p in requestParams) Symbol(p): json[p]
    });
  }

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
}
