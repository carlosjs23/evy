import 'dart:convert';
import 'dart:io';

import 'package:evy/evy.dart';
import 'package:test/test.dart';

void main() {
  final servers = <HttpServer>[];

  Future<int> start(Evy app) async {
    final server = await HttpServer.bind('localhost', 0);
    servers.add(server);
    server.listen(app.router.handle);
    return server.port;
  }

  tearDown(() async {
    for (final server in servers) {
      await server.close(force: true);
    }
    servers.clear();
  });

  Future<({int status, String body})> send(
    int port,
    String path,
    List<int> bytes, {
    String method = 'POST',
    String? contentType,
    int? contentLength,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.open(method, 'localhost', port, path);
      if (contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      if (contentLength != null) {
        request.contentLength = contentLength;
      }
      if (bytes.isNotEmpty) {
        request.add(bytes);
      }
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      return (status: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  Future<({int status, String body})> sendText(
    int port,
    String path,
    String body, {
    String method = 'POST',
    String? contentType,
  }) {
    return send(port, path, utf8.encode(body),
        method: method, contentType: contentType);
  }

  Future<int> startEchoApp(Function parser) async {
    final app = Evy();
    app.use(handler: parser);
    app.post(
        path: '/echo',
        handler: (Request req, Response res, Function next) async {
          res.send(jsonEncode(req.body));
        });
    return start(app);
  }

  group('BodyParser.json', () {
    test('parses a valid JSON object under the limit', () async {
      final port = await startEchoApp(BodyParser.json(limit: 1024));

      final result = await sendText(
          port, '/echo', jsonEncode({'name': 'John', 'age': 30}),
          contentType: 'application/json');

      expect(result.status, equals(200));
      expect(jsonDecode(result.body), equals({'name': 'John', 'age': 30}));
    });

    test('responds 400 when the body exceeds the limit (chunked)', () async {
      final port = await startEchoApp(BodyParser.json(limit: 10));

      final result = await sendText(
          port, '/echo', jsonEncode({'data': 'x' * 100}),
          contentType: 'application/json');

      expect(result.status, equals(400));
    });

    test('responds 400 when Content-Length exceeds the limit', () async {
      final port = await startEchoApp(BodyParser.json(limit: 10));

      final payload = utf8.encode(jsonEncode({'data': 'x' * 100}));
      final result = await send(port, '/echo', payload,
          contentType: 'application/json', contentLength: payload.length);

      expect(result.status, equals(400));
    });

    test('responds 400 on invalid UTF-8 and the server stays alive',
        () async {
      final port = await startEchoApp(BodyParser.json());

      final result = await send(port, '/echo', <int>[0xC3, 0x28],
          contentType: 'application/json');
      expect(result.status, equals(400));

      final followUp = await sendText(port, '/echo', jsonEncode({'ok': true}),
          contentType: 'application/json');
      expect(followUp.status, equals(200));
      expect(jsonDecode(followUp.body), equals({'ok': true}));
    });

    test('responds 400 on malformed JSON', () async {
      final port = await startEchoApp(BodyParser.json());

      final result = await sendText(port, '/echo', '{"name": ',
          contentType: 'application/json');

      expect(result.status, equals(400));
    });

    test('accepts a top-level JSON array', () async {
      final app = Evy();
      app.use(handler: BodyParser.json());
      app.post(
          path: '/items',
          handler: (Request req, Response res, Function next) async {
            final dynamic body = req.body;
            if (body is List) {
              res.send(jsonEncode({'sum': body.length, 'items': body}));
            } else {
              res.status(500);
              res.send('expected a List, got ${body.runtimeType}');
            }
          });
      final port = await start(app);

      final result = await sendText(port, '/items', '[1,2,3]',
          contentType: 'application/json');

      expect(result.status, equals(200));
      expect(
          jsonDecode(result.body),
          equals({
            'sum': 3,
            'items': [1, 2, 3]
          }));
    });

    test('leaves req.body null for an empty body', () async {
      final port = await startEchoApp(BodyParser.json());

      final result = await sendText(port, '/echo', '',
          contentType: 'application/json');

      expect(result.status, equals(200));
      expect(result.body, equals('null'));
    });

    test('skips GET requests', () async {
      final app = Evy();
      app.use(handler: BodyParser.json());
      app.get(
          path: '/data',
          handler: (Request req, Response res, Function next) async {
            res.send(jsonEncode(req.body));
          });
      final port = await start(app);

      final result = await sendText(port, '/data', '', method: 'GET');

      expect(result.status, equals(200));
      expect(result.body, equals('null'));
    });

    test('passes through non-matching content types without consuming body',
        () async {
      final port = await startEchoApp(BodyParser.json());

      final result = await sendText(port, '/echo', 'plain text',
          contentType: 'text/plain');

      expect(result.status, equals(200));
      expect(result.body, equals('null'));
    });
  });

  group('BodyParser.urlencoded', () {
    test('parses nested bracket keys', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(
          port, '/echo', 'user[name]=John&user[email]=j%40x.com',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(
          jsonDecode(result.body),
          equals({
            'user': {'name': 'John', 'email': 'j@x.com'}
          }));
    });

    test('parses deeply nested bracket keys', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(port, '/echo', 'a[b][c]=v',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(
          jsonDecode(result.body),
          equals({
            'a': {
              'b': {'c': 'v'}
            }
          }));
    });

    test('parses empty brackets as array push', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(port, '/echo', 'tags[]=x&tags[]=y',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(
          jsonDecode(result.body),
          equals({
            'tags': ['x', 'y']
          }));
    });

    test('collects duplicate scalar keys into a list', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(port, '/echo', 'name=John&name=Jane',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(
          jsonDecode(result.body),
          equals({
            'name': ['John', 'Jane']
          }));
    });

    test('decodes plain fields including + and percent escapes', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(
          port, '/echo', 'name=John+Doe&email=j%40x.com',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(jsonDecode(result.body),
          equals({'name': 'John Doe', 'email': 'j@x.com'}));
    });

    test('keeps bracket keys flat when extended is false', () async {
      final port = await startEchoApp(BodyParser.urlencoded(extended: false));

      final result = await sendText(port, '/echo', 'user[name]=John',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(jsonDecode(result.body), equals({'user[name]': 'John'}));
    });

    test('leaves req.body null for an empty body', () async {
      final port = await startEchoApp(BodyParser.urlencoded());

      final result = await sendText(port, '/echo', '',
          contentType: 'application/x-www-form-urlencoded');

      expect(result.status, equals(200));
      expect(result.body, equals('null'));
    });
  });

  group('BodyParser.text', () {
    test('sets req.body to the raw string', () async {
      final app = Evy();
      app.use(handler: BodyParser.text());
      app.post(
          path: '/raw',
          handler: (Request req, Response res, Function next) async {
            final dynamic body = req.body;
            if (body is String) {
              res.send('string:$body');
            } else {
              res.status(500);
              res.send('expected a String, got ${body.runtimeType}');
            }
          });
      final port = await start(app);

      final result = await sendText(port, '/raw', 'hello world',
          contentType: 'text/plain');

      expect(result.status, equals(200));
      expect(result.body, equals('string:hello world'));
    });
  });

  group('Request.contentType', () {
    test('returns a ContentType instance', () async {
      final app = Evy();
      app.post(
          path: '/ct',
          handler: (Request req, Response res, Function next) async {
            final dynamic contentType = req.contentType;
            res.send(
                '${contentType is ContentType}:${contentType is ContentType ? contentType.mimeType : contentType}');
          });
      final port = await start(app);

      final result = await sendText(port, '/ct', '{}',
          contentType: 'application/json; charset=utf-8');

      expect(result.status, equals(200));
      expect(result.body, equals('true:application/json'));
    });
  });
}
