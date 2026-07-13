import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evy/evy.dart';
import 'package:evy/src/router/route.dart';
import 'package:test/test.dart';

Future<HttpServer> _serve(Evy app) async {
  final server = await HttpServer.bind('localhost', 0);
  server.listen(app.router.handle);
  addTearDown(() => server.close(force: true));
  return server;
}

Future<(int, String)> _request(int port, String method, String path) async {
  final client = HttpClient();
  try {
    final request = await client
        .openUrl(method, Uri.parse('http://localhost:$port$path'))
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
  group('Route.post', () {
    test('accepts a List<Callback> handler', () async {
      final app = Evy();

      Future<void> mw(Request req, Response res, Function next) async {
        (req.params ??= {})['injected'] = 'mw-was-here';
        await next();
      }

      Future<void> handler(Request req, Response res, Function next) async {
        res.send('users:${req.params!['injected']}');
      }

      app.post(path: '/users', handler: [mw, handler]);

      final server = await _serve(app);
      final (status, body) = await _request(server.port, 'POST', '/users');

      expect(status, equals(200));
      expect(body, equals('users:mw-was-here'));
    });

    test('still works with a single callback', () async {
      final app = Evy();

      Future<void> handler(Request req, Response res, Function next) async {
        res.send('single ok');
      }

      app.post(path: '/single', handler: handler);

      final server = await _serve(app);
      final (status, body) = await _request(server.port, 'POST', '/single');

      expect(status, equals(200));
      expect(body, equals('single ok'));
    });
  });

  group('Route chaining', () {
    test('chained get handlers run in order', () async {
      final app = Evy();
      var seen = '';

      Future<void> h1(Request req, Response res, Function next) async {
        seen = 'h1';
        await next();
      }

      Future<void> h2(Request req, Response res, Function next) async {
        res.send('chain:$seen');
      }

      app.route('/chain').get(h1).get(h2);

      final server = await _serve(app);
      final (status, body) = await _request(server.port, 'GET', '/chain');

      expect(status, equals(200));
      expect(body, equals('chain:h1'));
    });

    test('next() past the end of the stack completes cleanly', () async {
      final app = Evy();

      Future<void> h1(Request req, Response res, Function next) async {
        await next();
      }

      Future<void> h2(Request req, Response res, Function next) async {
        res.send('done');
        await next();
      }

      app.route('/exhaust').get(h1).get(h2);

      final server = await _serve(app);
      final (status, body) = await _request(server.port, 'GET', '/exhaust');

      expect(status, equals(200));
      expect(body, equals('done'));
    });
  });

  group('Route.dispatch finish callback', () {
    test('invokes the caller finish when the stack is exhausted', () async {
      Future<void> passThrough(
          Request req, Response res, Function next) async {
        await next();
      }

      final server = await HttpServer.bind('localhost', 0);
      addTearDown(() => server.close(force: true));
      server.listen((httpRequest) async {
        final request = Request.from(httpRequest);
        final response = Response(httpRequest.response);
        final route = Route('/direct').get(passThrough).get(passThrough);
        await route.dispatch(request, response, () async {
          response.send('finished');
        });
      });

      final (status, body) = await _request(server.port, 'GET', '/direct');

      expect(status, equals(200));
      expect(body, equals('finished'));
    });

    test('invokes the caller finish when the method does not match', () async {
      Future<void> handler(Request req, Response res, Function next) async {
        res.send('should not run');
      }

      final server = await HttpServer.bind('localhost', 0);
      addTearDown(() => server.close(force: true));
      server.listen((httpRequest) async {
        final request = Request.from(httpRequest);
        final response = Response(httpRequest.response);
        final route = Route('/only-post').post(handler);
        await route.dispatch(request, response, () async {
          response.send('method-finish');
        });
      });

      final (status, body) = await _request(server.port, 'GET', '/only-post');

      expect(status, equals(200));
      expect(body, equals('method-finish'));
    });

    test('invokes the caller finish when the stack is empty', () async {
      final server = await HttpServer.bind('localhost', 0);
      addTearDown(() => server.close(force: true));
      server.listen((httpRequest) async {
        final request = Request.from(httpRequest);
        final response = Response(httpRequest.response);
        final route = Route('/empty');
        await route.dispatch(request, response, () async {
          response.send('empty-finish');
        });
      });

      final (status, body) = await _request(server.port, 'GET', '/empty');

      expect(status, equals(200));
      expect(body, equals('empty-finish'));
    });
  });
}
