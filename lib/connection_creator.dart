import 'dart:async';

import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getConnection() async {
  var settings = ConnectionSettings(
    host: 'db',
    port: 3306,
    user: 'user',
    password: 'user',
    db: 'ondemand',
    timeout: Duration(seconds: 20),
  );

  return await _createConnection(settings);
}

Future<MySqlConnection> _createConnection(ConnectionSettings settings) {
  var completer = Completer<MySqlConnection>();
  Timer(
      Duration(seconds: 2),
          () => MySqlConnection.connect(settings)
          .then(completer.complete)
          .catchError(
              (e) => _createConnection(settings).then(completer.complete)));
  return completer.future;
}