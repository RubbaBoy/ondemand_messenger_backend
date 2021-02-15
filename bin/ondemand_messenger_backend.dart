
import 'package:args/args.dart';
import 'package:ondemand_messenger_backend/fetcher.dart';
import 'package:ondemand_messenger_backend/server.dart';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('port', abbr: 's', help: 'The socket port', defaultsTo: '8090')
    ..addOption('driverport',
        abbr: 'd', help: 'The socket port', defaultsTo: '4444');

  var result = parser.parse(args);

  var tokenFetcher = TokenFetcher();
  await tokenFetcher.init(int.parse(result['driverport']));

  print('Binding...');

  await Server(tokenFetcher)
      .start(int.parse(result['port']));
}
