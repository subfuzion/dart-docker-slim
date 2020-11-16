import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

const _hostname = '0.0.0.0';

void main(List<String> args) async {
  var watch = Stopwatch()..start();
  print('Starting server');

  var parser = ArgParser()
    ..addFlag('quit', defaultsTo: false, negatable: false);
  var result = parser.parse(args);

  var portStr = Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  var quit = result['quit'] ?? false;

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    exitCode = 64; // command line usage error
    return;
  }

  var handler = const shelf.Pipeline().addHandler(_echoRequest);

  handleSignals();

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');

  if (quit) {
    // exit immediately for server launch timing test if --quit option set
    print('time elapsed: ${watch.elapsedMilliseconds} ms');
    exit(0);
  }
}

shelf.Response _echoRequest(shelf.Request request) =>
    shelf.Response.ok('Request for "${request.url}"');

void handleSignals() {
  ProcessSignal.sigint.watch().listen((signal) {
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((signal) {
    exit(0);
  });
}
