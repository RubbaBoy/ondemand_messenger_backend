import 'dart:math';

import 'utility.dart';

class TokenUtils {
  static final possibleChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random();

  /// Tests if a given string token is a valid and unexpired token.
  /// A token begins with 10 random characters, 13 digits of the expiry time in
  /// milliseconds, and another 9 random characters, for a total length of 32
  /// characters.
  static bool isValid(String token) {
    if (token == null) {
      return false;
    }

    if (token.length != 32) {
      return false;
    }

    if (!token.split('').containedWithin(possibleChars.split(''))) {
      return false;
    }

    if (!isNumeric(token.substring(10, 23))) {
      return false;
    }

    return true;
  }

  /// Checks the date, returns true if the time to expiry has passed. This
  /// assumes [isValid] has been invoked and is true.
  static bool isExpired(String token) {
    var time =
        DateTime.fromMillisecondsSinceEpoch(token.substring(10, 23).toInt());
    if (time.isBefore(DateTime.now())) {
      // Token is expired, as expiry is before the current time
      return false;
    }

    return true;
  }

  static Token generateToken(Duration expiration) {
    var expiry = DateTime.now().add(expiration);

    return Token._(
        '${random(10)}'
        '${expiry.millisecondsSinceEpoch}'
        '${random(9)}',
        expiry);
  }

  static String random(int length) => String.fromCharCodes([
        for (int i = 0; i < length; i++)
          possibleChars.codeUnitAt(_random.nextInt(possibleChars.length))
      ]);
}

class Token {
  final String token;
  final DateTime expiry;

  Token._(this.token, this.expiry);
}
