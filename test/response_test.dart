import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evy/evy.dart';
import 'package:test/test.dart';

Future<HttpServer> _serve(Evy app) async {
  final server = await HttpServer.bind('localhost', 0);
  server.listen(app.router.handle);
  addTearDown(() => server.close(force: true));
  return server;
}

Future<(int, String)> _get(int port, String path) async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse('http://localhost:$port$path'))
        .timeout(Duration(seconds: 5));
    final response = await request.close().timeout(Duration(seconds: 5));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(Duration(seconds: 5));
    return (response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}

void main() {
  group('Response.status', () {
    test('is chainable with send', () async {
      final app = Evy();

      Future<void> handler(Request req, Response res, Function next) async {
        res.status(404).send('nope');
      }

      app.get(path: '/missing', handler: handler);

      final server = await _serve(app);
      final (status, body) = await _get(server.port, '/missing');

      expect(status, equals(404));
      expect(body, equals('nope'));
    });

    test('returns the same Response instance', () async {
      final app = Evy();
      var isSameInstance = false;

      Future<void> handler(Request req, Response res, Function next) async {
        isSameInstance = identical(res.status(418), res);
        res.send('teapot');
      }

      app.get(path: '/teapot', handler: handler);

      final server = await _serve(app);
      final (status, body) = await _get(server.port, '/teapot');

      expect(status, equals(418));
      expect(body, equals('teapot'));
      expect(isSameInstance, isTrue);
    });
  });

  group('Response.statusCode', () {
    test('still sets the status code (backward compat)', () async {
      final app = Evy();

      Future<void> handler(Request req, Response res, Function next) async {
        res.statusCode(201);
        res.send('created');
      }

      app.get(path: '/created', handler: handler);

      final server = await _serve(app);
      final (status, body) = await _get(server.port, '/created');

      expect(status, equals(201));
      expect(body, equals('created'));
    });
  });
}
