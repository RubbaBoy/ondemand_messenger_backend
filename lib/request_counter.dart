import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/connection_creator.dart';

class RequestCounter {
  final RetryMySqlConnection _conn;

  RequestCounter._(this._conn);

  static Future<RequestCounter> createRequestCounter(RetryMySqlConnection conn) async {
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
