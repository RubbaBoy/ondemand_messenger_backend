
import 'dart:io';

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
