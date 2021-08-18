import 'dart:async';

import 'package:mysql1/mysql1.dart';

RetryMySqlConnection getConnection() {
  var settings = ConnectionSettings(
    host: 'db',
    port: 3306,
    user: 'user',
    password: 'user',
    db: 'ondemand',
    timeout: Duration(seconds: 20),
  );

  return RetryMySqlConnection(settings);
}

class RetryMySqlConnection {
  final ConnectionSettings _settings;

  RetryMySqlConnection(this._settings);

  MySqlConnection _conn;

  Future<void> _reloadConnection() async =>
      _conn = await _createConnection();

  Future<MySqlConnection> _createConnection() {
    var completer = Completer<MySqlConnection>();
    Timer(
        Duration(seconds: 2),
            () => MySqlConnection.connect(_settings)
            .then(completer.complete)
            .catchError(
                (e) => _createConnection().then(completer.complete)));
    return completer.future;
  }

  Future<Results> query(String sql, [List<Object> values]) async {
    try {
      return _conn.query(sql, values);
    } catch (e) {
      print('Reloading connection on (${e.runtimeType}) error $e');
      await _reloadConnection();
      return query(sql, values);
    }
  }

  Future<List<Results>> queryMulti(
      String sql, Iterable<List<Object>> values) async {
    try {
      return _conn.queryMulti(sql, values);
    } catch (e) {
      print('Reloading connection on (${e.runtimeType}) error $e');
      await _reloadConnection();
      return queryMulti(sql, values);
    }
  }

  Future transaction(Function queryBlock) async {
    try {
      return _conn.transaction(queryBlock);
    } catch (e) {
      print('Reloading connection on (${e.runtimeType}) error $e');
      await _reloadConnection();
      return transaction(queryBlock);
    }
  }
}
