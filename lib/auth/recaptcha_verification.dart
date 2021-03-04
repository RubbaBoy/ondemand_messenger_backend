import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ondemand_messenger_backend/auth/verifier.dart';

class CaptchaVerification with Verifier {
  final String _captchaSecret;

  CaptchaVerification(this._captchaSecret);

  /// Sends a request to Google to check if the given reCaptcha [token] is
  /// valid.
  @override
  Future<bool> isValid(String token) async {
    var response = await http.post(
        Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'secret=$_captchaSecret&response=$token');
    var json = jsonDecode(response.body);
    print(json);
    return json['success'] ?? false;
  }
}
