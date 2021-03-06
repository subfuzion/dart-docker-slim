import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:io' show Platform;
import 'package:test/test.dart';

const _defaultHost = 'localhost';
const _defaultPort = '8080';

void main() {
  var serverUrl = Uri(scheme: 'http', host: 'localhost', port: 8080);

  setUp(() {
    var host = Platform.environment['HOST'] ?? _defaultHost;
    var portStr = Platform.environment['PORT'] ?? _defaultPort;
    var port = int.parse(portStr);
    serverUrl = serverUrl.replace(scheme: 'http', host: host, port: port);
  });

  group('Is server reachable?', () {
    test('ping-test', () async {
      var url = serverUrl.replace(path: '/ping-test');
      var resp = await http.read(url);
      if (resp != 'ok') {
        print('error: connection failed ($url). Is server running?');
        exit(1);
      }
    });
  });

  group('Server - DNS client tests', () {
    test('remote-ping-test', () async {
      var url = serverUrl.replace(path: '/remote-ping-test');
      var resp = await http.read(url);
      expect(resp, equals('ok'));
    });
  });

  group('Server - TLS client cert tests', () {
    test('client-certs-test', () async {
      var url = serverUrl.replace(path: '/client-certs-test');
      var resp = await http.read(url);
      expect(resp, equals('ok'));
    });
  });
}
