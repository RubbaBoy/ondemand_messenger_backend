
import 'dart:io';

import 'package:intl/intl.dart';

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

extension ListUtils<E> on List<E> {
  /// Returns if the current list's elements are all present in the given
  /// [subList].
  bool containedWithin(List<E> subList) => !any((e) => !subList.contains(e));
}

extension StringUtils on String {
  int toInt() => int.tryParse(this);
}
