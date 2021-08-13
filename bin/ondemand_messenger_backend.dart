import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:ondemand_messenger_backend/auth/book_auth_manager.dart';
import 'package:ondemand_messenger_backend/auth/captcha_auth_manager.dart';
import 'package:ondemand_messenger_backend/auth/recaptcha_verification.dart';
import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/connection_creator.dart'
    as conn_creator;
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/request_counter.dart';
import 'package:ondemand_messenger_backend/server.dart';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('port', abbr: 's', help: 'The socket port', defaultsTo: '8090')
    ..addOption('override',
        abbr: 'o', help: 'The override password', defaultsTo: 'pass');

  var result = parser.parse(args);

  print('Connecting to database...');

  var conn = await conn_creator.getConnection();

  print('Connected to database');

  var bookManager = await BookManager.createBookManager(conn);
  var requestCounter = await RequestCounter.createRequestCounter(conn);

  var captchaAuthManager = CaptchaAuthManager(conn);
  await captchaAuthManager.init();

  print('Created book manager');
  await Server(
          TokenFetcher(),
          bookManager,
          BookAuthManager(bookManager),
          captchaAuthManager,
          CaptchaVerification(Platform.environment['CAPTCHA_SECRET']),
          requestCounter,
          result['override'])
      .start(int.parse(result['port']));
}
