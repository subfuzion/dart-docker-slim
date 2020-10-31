import 'dart:io';

import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

const _defaultHost = '0.0.0.0';
const _defaultPort = '8080';

void main(List<String> args) async {
  var host = Platform.environment['HOST'] ?? _defaultHost;
  var portStr = Platform.environment['PORT'] ?? _defaultPort;
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse environment variable for port "$portStr" into a number.');
    exitCode = 1;
    return;
  }

  handleSignals();

  var app = Router();

  app.get('/', (shelf.Request req) => shelf.Response.ok('ok'));

  app.get('/ping-test', (shelf.Request req) => shelf.Response.ok('ok'));

  app.get('/remote-ping-test', (shelf.Request req) async {
    const url = 'http://urlecho.appspot.com/echo?body=ok';
    var resp = await http.read(url);
    if (resp != 'ok') {
      return shelf.Response.internalServerError(body: 'remote request failed');
    }
    return shelf.Response.ok('ok');
  });

  var server = await io.serve(app.handler, host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

void handleSignals() {
  ProcessSignal.sigint.watch().listen((signal) {
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((signal) {
    exit(0);
  });
}