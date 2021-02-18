import 'dart:async';

import 'package:args/args.dart';
import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/server.dart';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('port', abbr: 's', help: 'The socket port', defaultsTo: '8090');

  var result = parser.parse(args);

  print('Binding...');

  var settings = ConnectionSettings(
    host: 'db',
    port: 3306,
    user: 'root',
    password: 'example',
    db: 'ondemand',
    timeout: Duration(seconds: 20),
  );

  var conn = await createConnection(settings);

  print('Connected to database');

  await Server(TokenFetcher(), conn).start(int.parse(result['port']));
}

Future<T> delay<T>(Duration duration, FutureOr<T> Function() value) {
  var completer = Completer<T>();
  Timer(duration, () async => completer.complete(await value()));
  return completer.future;
}

Future<MySqlConnection> createConnection(ConnectionSettings settings) {
  var completer = Completer<MySqlConnection>();
  Timer(
      Duration(seconds: 1),
      () => MySqlConnection.connect(settings)
          .then(completer.complete)
          .catchError(
              (e) => createConnection(settings).then(completer.complete)));
  return completer.future;
}
