import 'dart:convert';
import 'dart:io';

import 'package:ondemand_messenger_backend/auth/book_auth_manager.dart';
import 'package:ondemand_messenger_backend/auth/captcha_auth_manager.dart';
import 'package:ondemand_messenger_backend/auth/recaptcha_verification.dart';
import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/request_helper.dart';
import 'package:ondemand_messenger_backend/token_utils.dart';
import 'package:ondemand_messenger_backend/utility.dart';

class Server {
  final BookAuthManager _bookAuthManager;
  final TokenFetcher _tokenFetcher;
  final BookManager _bookManager;
  final CaptchaAuthManager _captchaAuthManager;
  final CaptchaVerification _captchaVerification;
  final String overridePassword;

  Server(this._tokenFetcher, this._bookManager, this._bookAuthManager, this._captchaAuthManager, this._captchaVerification, this.overridePassword);

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
    var response = request.response;
    response.headers.set('Access-Control-Allow-Origin', 'https://yarr.is');
    response.headers.set('Access-Control-Expose-Headers', 'x-token');

    if (request.method != 'POST') {
      response.write(jsonEncode({'error': 'POST Only'}));
    } else {
      response.write(jsonEncode(await handlePost(request)));
    }

    await response.close();
  }

  Future<Map<String, dynamic>> handlePost(HttpRequest request) async {
    var path = request.uri.pathSegments;
    var response = request.response;

    if (path.length != 1) {
      response.statusCode = HttpStatus.methodNotAllowed;
      return {'error': 'Not Found'};
    }

    var res = ({
      'sendSMS': (re, rs) =>
          ensureParameters(request, response, sendSMS,
              requestParams: ['number', 'message']),
      'requestToken': (re, rs) =>
          ensureParameters(request, response, requestToken,
              requestParams: ['name', 'password']),
      'requestCaptchaOverride': (re, rs) =>
          ensureParameters(request, response, requestCaptchaOverride,
              requestParams: ['password', 'label'], captchaRequest: false),
      'createBook': (re, rs) =>
          ensureParameters(request, response, createBook,
              requestParams: ['name', 'password']),
      'getBook': (re, rs) =>
          ensureParameters(re, rs, getBook, bookRequest: true),
      'addNumber': (re, rs) =>
          ensureParameters(re, rs, addNumber,
              bookRequest: true, requestParams: ['numberName', 'number']),
      'removeNumber': (re, rs) =>
          ensureParameters(re, rs, removeNumber,
              bookRequest: true, requestParams: ['numberId']),
    })[path[0]]
        ?.call(request, response);

    if (res != null) {
      return await res;
    }

    return error(response, HttpStatus.notFound, 'Not Found');
  }

  Future<Map<String, dynamic>> sendSMS(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json,
      {String number, String message}) async {
    number = parsePhoneNumber(number);

    if (number == null || !isNumeric(number)) {
      return error(response, HttpStatus.badRequest,
          'number must be a 10 digit phone number (or longer with international code)');
    }

    if (message.isEmpty || message.length > 4096) {
      return error(response, HttpStatus.badRequest,
          'message length must be 1-4096 characters');
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

  String getTokenHeaderString(Token token) =>
      '${token.token};${toUTCString(token.expiry)}';

  Future<Map<String, dynamic>> createBook(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json,
      {String name, String password}) async {
    if (_bookManager.containsBook(name)) {
      return error(
          response, HttpStatus.badRequest, 'Book with name already exists');
    }

    var book = await _bookManager.addBook(name, password);
    var token = _bookAuthManager.getToken(book: book);

    response.headers.add('x-token', getTokenHeaderString(token));
    return {
      'book': {'id': book.bookId, 'name': book.name}
    };
  }

  Future<Map<String, dynamic>> requestToken(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json,
      {String name, String password}) async {
    var token = _bookAuthManager.getToken(username: name, password: password);

    if (token == null) {
      return error(response, HttpStatus.unauthorized, 'Invalid credentials');
    }

    response.headers.add('x-token', getTokenHeaderString(token));
    return {};
  }

  Future<Map<String, dynamic>> requestCaptchaOverride(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json,
      {String password, String label}) async {
    print('Creating reCaptcha override!');

    if (password != overridePassword) {
      return error(response, HttpStatus.unauthorized, 'Invalid credentials');
    }

    return (await _captchaAuthManager.createToken(label)).toJson();
  }

  Future<Map<String, dynamic>> getBook(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book) async {
    return {
      'numbers': _bookManager.getNumbers(book).map((e) => e.toJson()).toList()
    };
  }

  Future<Map<String, dynamic>> addNumber(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book,
      {String numberName, String number}) async {
    number = parsePhoneNumber(number);

    if (number == null || !isNumeric(number)) {
      return error(response, HttpStatus.badRequest,
          'number must be a 10 digit phone number (or longer with international code)');
    }

    var addedNumber = await _bookManager.addNumber(numberName, number, book);
    return {'number': addedNumber.toJson()};
  }

  Future<Map<String, dynamic>> removeNumber(HttpRequest request,
      HttpResponse response, Map<String, dynamic> json, Book book,
      {int numberId}) async {
    await _bookManager.removeNumber(numberId);
    return {};
  }

  /// [bookRequest] requires a `token` header.
  /// [captchaRequest] requires either a `captchaToken` or `captchaOverride`
  /// access token.
  /// The `captchaToken` comes directly from reCaptcha. `captchaOverride` is an
  /// access token retrieved by [requestCaptchaOverride].
  Future<Map<String, dynamic>> ensureParameters(HttpRequest request,
      HttpResponse response, Function callback,
      {List<String> requestParams = const [], bool bookRequest = false, bool captchaRequest = true}) async {
    var json = await getBody(request);

    var testingParams = [
      ...requestParams,
      if (bookRequest) 'token'
    ];

    if (testingParams.any((element) => !json.containsKey(element))) {
      return error(response, HttpStatus.badRequest,
          'Required parameters: ${testingParams.join(', ')}');
    }

    if (captchaRequest) {
      var override = json.containsKey('captchaOverride');
      var token = override ? json['captchaOverride'] : json['captchaToken'];
      var verifier = override ? _captchaAuthManager : _captchaVerification;
      if (token == null || !await verifier.isValid(token)) {
        return error(response, HttpStatus.unauthorized, 'Invalid ${override ? 'override' : 'reCaptcha'} token');
      }
    }

    Book book;
    if (bookRequest) {
      var token = json['token'];

      var bookResult = _bookAuthManager.getBook(token);
      switch (bookResult.result) {
        case Result.Invalid:
          return error(response, HttpStatus.unauthorized, 'Invalid token');
        case Result.Expired:
          return error(response, HttpStatus.unauthorized, 'Expired token');
        case Result.Okay:
          book = bookResult.book;
          break;
      }
    }

    try {
      return Function.apply(
          callback,
          [request, response, json, if (book != null) book],
          {for (var p in requestParams) Symbol(p): json[p]});
    } catch (e, s) {
      print('An error occurred\n$e\n$s');
      return error(response, HttpStatus.internalServerError, '$e');
    }
  }
}
