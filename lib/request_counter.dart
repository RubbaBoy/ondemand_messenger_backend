import 'package:mysql1/mysql1.dart';

class RequestCounter {
  final MySqlConnection _conn;

  RequestCounter._(this._conn);

  static Future<RequestCounter> createRequestCounter(MySqlConnection conn) async {
    if ((await conn.query('SELECT * FROM sentMessages;')).isEmpty) {
      await conn.query('INSERT INTO sentMessages (count) VALUES(0)');
    }

    return RequestCounter._(conn);
  }

  Future<void> increment() async {
    await _conn.query('UPDATE sentMessages SET count = count + 1;');
  }

  Future<int> getCount() async {
    var queriedCount = await _conn.query('SELECT count FROM sentMessages;');

    if (queriedCount.isEmpty) {
      print('Queried sentMessages is empty!');
      return 0;
    }

    return queriedCount.first['count'];
  }
}
