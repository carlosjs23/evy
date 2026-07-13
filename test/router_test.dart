import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evy/evy.dart';
import 'package:test/test.dart';

Future<({int status, String body})> getRequest(int port, String path) async {
  final client = HttpClient();
  try {
    final request = await client.get('localhost', port, path);
    final response = await request.close();
    final body = await utf8.decodeStream(response);
    return (status: response.statusCode, body: body);
  } finally {
    client.close();
  }
}

void main() {
  late HttpServer server;
  late int port;

  Future<void> serve(Evy app) async {
    server = await HttpServer.bind('localhost', 0);
    server.listen(app.router.handle);
    port = server.port;
  }

  tearDown(() async {
    await server.close(force: true);
  });

  group('route params', () {
    test('are extracted for a plain param route', () async {
      final app = Evy();
      app.get(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            res.send('Hello ${req.params?['name']}');
          });
      await serve(app);

      final result = await getRequest(port, '/greet/Alberto');
      expect(result.status, equals(200));
      expect(result.body, equals('Hello Alberto'));
    });

    test('are not clobbered by global middleware that sets params', () async {
      final app = Evy();
      app.use(handler: (Request req, Response res, next) async {
        req.params ??= {};
        req.params!['injected'] = 'yes';
        await next();
      });
      app.get(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            res.send(
                'name=${req.params?['name']} injected=${req.params?['injected']}');
          });
      await serve(app);

      final result = await getRequest(port, '/greet/Alberto');
      expect(result.status, equals(200));
      expect(result.body, equals('name=Alberto injected=yes'));
    });

    test('mutations by earlier middleware persist to later handlers',
        () async {
      final app = Evy();
      app.use(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            if (req.params?['name'] == 'Alberto') {
              req.params!['name'] = 'Carlos';
            }
            await next();
          });
      app.get(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            res.send('Hello ${req.params?['name']}');
          });
      await serve(app);

      final result = await getRequest(port, '/greet/Alberto');
      expect(result.status, equals(200));
      expect(result.body, equals('Hello Carlos'));
    });

    test('are merged across multiple path-matched middlewares', () async {
      final app = Evy();
      final seen = <String, dynamic>{};
      app.use(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            seen['middleware'] = req.params?['name'];
            req.params!['checked'] = 'ok';
            await next();
          });
      app.get(
          path: '/greet/:name',
          handler: (Request req, Response res, next) async {
            res.send(
                'name=${req.params?['name']} checked=${req.params?['checked']}');
          });
      await serve(app);

      final result = await getRequest(port, '/greet/Alberto');
      expect(seen['middleware'], equals('Alberto'));
      expect(result.status, equals(200));
      expect(result.body, equals('name=Alberto checked=ok'));
    });
  });

  group('error handling', () {
    test('handler throwing before sending yields a 500 response', () async {
      final app = Evy();
      app.get(
          path: '/boom',
          handler: (Request req, Response res, next) async {
            throw Exception('boom');
          });
      await serve(app);

      final result = await getRequest(port, '/boom');
      expect(result.status, equals(500));
      expect(result.body, equals('Internal Server Error'));
    });

    test('handler throwing after sending does not kill the server', () async {
      final app = Evy();
      app.get(
          path: '/partial',
          handler: (Request req, Response res, next) async {
            res.send('partial');
            throw Exception('after send');
          });
      app.get(
          path: '/healthy',
          handler: (Request req, Response res, next) async {
            res.send('ok');
          });
      await serve(app);

      final partial = await getRequest(port, '/partial');
      expect(partial.status, equals(200));
      expect(partial.body, equals('partial'));

      final healthy = await getRequest(port, '/healthy');
      expect(healthy.status, equals(200));
      expect(healthy.body, equals('ok'));
    });

    test('unhandled handler errors are logged', () async {
      final app = Evy();
      app.get(
          path: '/boom',
          handler: (Request req, Response res, next) async {
            throw Exception('boom');
          });

      final logs = <String>[];
      await runZoned(() async {
        await serve(app);
        final result = await getRequest(port, '/boom');
        expect(result.status, equals(500));
        await Future.delayed(Duration(milliseconds: 50));
      },
          zoneSpecification: ZoneSpecification(
              print: (self, parent, zone, line) => logs.add(line)));

      expect(
          logs,
          contains(contains(
              'Unhandled error while handling GET /boom: Exception: boom')));
    });
  });
}
