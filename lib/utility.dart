
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/connection_creator.dart';

final format = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
final httpClient = HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

bool isNumeric(String s) => s != null && double.parse(s) != null;

String parsePhoneNumber(String number) {
  number = number.replaceAll(RegExp(r'\D'), '');
  if (number.length < 10) {
    return null;
  }

  if (number.length == 10) {
    number = '1$number';
  }

  return number;
}

String toUTCString(DateTime dateTime) => '${format.format(dateTime.toUtc())} UTC';

Future<int> getLastId(RetryMySqlConnection conn) async {
  var idRow = await conn.query('SELECT LAST_INSERT_ID()');
  return idRow.first.values[0];
}

extension ListUtils<E> on List<E> {
  /// Returns if the current list's elements are all present in the given
  /// [subList].
  bool containedWithin(List<E> subList) => !any((e) => !subList.contains(e));
}

extension StringUtils on String {
  int toInt() => int.tryParse(this);
}
