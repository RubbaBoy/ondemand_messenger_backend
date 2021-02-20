import 'dart:async';

import 'package:args/args.dart';
import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/connection_creator.dart' as conn_creator;
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/server.dart';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('port', abbr: 's', help: 'The socket port', defaultsTo: '8090');

  var result = parser.parse(args);

  print('Connecting to database...');

  var conn = await conn_creator.getConnection();

  print('Connected to database');

  var bookManager = await BookManager.createBookManager(conn);

  print('Created book manager');

  await Server(TokenFetcher(), bookManager)
      .start(int.parse(result['port']));
}
