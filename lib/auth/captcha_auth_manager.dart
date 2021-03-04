import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/auth/verifier.dart';
import 'package:ondemand_messenger_backend/token_utils.dart';
import 'package:ondemand_messenger_backend/utility.dart';

class CaptchaAuthManager with Verifier {
  final MySqlConnection _conn;
  final List<OverrideToken> tokens = [];

  CaptchaAuthManager(this._conn);

  /// Initializes tokens from the database.
  Future<void> init() async {
    var queriedTokens = await _conn.query('SELECT * FROM overrideTokens;');
    tokens
      ..clear()
      ..addAll(queriedTokens.map((row) => OverrideToken.fromRow(row)).toList());
    print('Loaded ${tokens.length} captcha override tokens');
  }

  /// Creates a token with the given [label] and adds it to the database. The
  /// [OverrideToken] is returned. Tokens are 64 characters long.
  Future<OverrideToken> createToken(String label) async {
    var token = TokenUtils.random(64);
    await _conn.query('INSERT INTO overrideTokens (label, token) VALUES(?, ?)',
        [label, token]);
    var id = await getLastId(_conn);
    var overrideToken = OverrideToken._(id, label, token);
    tokens.add(overrideToken);
    return overrideToken;
  }

  /// Checks if the given token is valid.
  @override
  bool isValid(String token) => tokens.any((e) => e.token == token);
}

class OverrideToken {
  final int id;
  final String label;
  final String token;

  OverrideToken._(this.id, this.label, this.token);

  OverrideToken.fromRow(Row row)
      : id = row['id'],
        label = row['label'],
        token = row['token'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'token': token,
  };
}
