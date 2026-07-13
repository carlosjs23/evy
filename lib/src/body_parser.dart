import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';

class BodyParser {
  /// Middleware for parsing JSON request bodies
  static Function json({int? limit}) {
    return (Request req, Response res, Function next) async {
      if (req.method == 'GET' || req.method == 'HEAD') {
        return await next();
      }

      if (req.contentType?.mimeType != 'application/json') {
        return await next();
      }

      try {
        final body = await _readBody(req.httpRequest, limit);
        if (body.isNotEmpty) {
          req.body = jsonDecode(body);
        }
        await next();
      } catch (e) {
        res.status(400);
        res.send('Bad Request: Invalid JSON');
      }
    };
  }

  /// Middleware for parsing URL-encoded form data
  static Function urlencoded({bool extended = true, int? limit}) {
    return (Request req, Response res, Function next) async {
      if (req.method == 'GET' || req.method == 'HEAD') {
        return await next();
      }

      if (req.contentType?.mimeType != 'application/x-www-form-urlencoded') {
        return await next();
      }

      try {
        final body = await _readBody(req.httpRequest, limit);
        if (body.isNotEmpty) {
          req.body = _parseUrlEncoded(body, extended);
        }
        await next();
      } catch (e) {
        res.status(400);
        res.send('Bad Request: Invalid form data');
      }
    };
  }

  /// Middleware for parsing raw text bodies
  static Function text({int? limit}) {
    return (Request req, Response res, Function next) async {
      if (req.method == 'GET' || req.method == 'HEAD') {
        return await next();
      }

      final mimeType = req.contentType?.mimeType;
      if (mimeType == null || !mimeType.startsWith('text/')) {
        return await next();
      }

      try {
        final body = await _readBody(req.httpRequest, limit);
        req.body = body;
        await next();
      } catch (e) {
        res.status(400);
        res.send('Bad Request: Could not read body');
      }
    };
  }

  /// Read the raw body from the HTTP request
  static Future<String> _readBody(HttpRequest request, int? limit) async {
    final contentLength = request.headers.contentLength;
    if (limit != null && contentLength > limit) {
      throw Exception('Request body too large');
    }

    final builder =
        await request.fold<BytesBuilder>(BytesBuilder(), (builder, chunk) {
      builder.add(chunk);
      if (limit != null && builder.length > limit) {
        throw Exception('Request body too large');
      }
      return builder;
    });

    return utf8.decode(builder.takeBytes());
  }

  /// Parse URL-encoded form data
  static Map<String, dynamic> _parseUrlEncoded(String body, bool extended) {
    final result = <String, dynamic>{};

    if (body.isEmpty) return result;

    final pairs = body.split('&');
    for (final pair in pairs) {
      final index = pair.indexOf('=');
      String key, value;

      if (index == -1) {
        key = Uri.decodeQueryComponent(pair);
        value = '';
      } else {
        key = Uri.decodeQueryComponent(pair.substring(0, index));
        value = Uri.decodeQueryComponent(pair.substring(index + 1));
      }

      final segments = extended ? _parseKeySegments(key) : null;
      if (segments != null && segments.length > 1) {
        _setNestedValue(result, segments, value);
      } else {
        if (result.containsKey(key)) {
          if (result[key] is List) {
            (result[key] as List).add(value);
          } else {
            result[key] = [result[key], value];
          }
        } else {
          result[key] = value;
        }
      }
    }

    return result;
  }

  /// Split a key like `a[b][c]` into segments ['a', 'b', 'c'].
  /// A trailing empty segment (e.g. `tags[]`) means an array push.
  /// Returns null when the brackets are malformed.
  static List<String>? _parseKeySegments(String key) {
    final match = RegExp(r'^([^\[\]]+)((?:\[[^\[\]]*\])*)$').firstMatch(key);
    if (match == null) return null;

    final segments = <String>[match.group(1)!];
    for (final bracket in RegExp(r'\[([^\[\]]*)\]').allMatches(match.group(2)!)) {
      segments.add(bracket.group(1)!);
    }
    return segments;
  }

  /// Set nested values for extended URL encoding (e.g., user[name]=John)
  static void _setNestedValue(
      Map<String, dynamic> result, List<String> segments, String value) {
    final isArrayPush = segments.last.isEmpty;
    final path =
        isArrayPush ? segments.sublist(0, segments.length - 1) : segments;

    Map<String, dynamic> current = result;
    for (var i = 0; i < path.length - 1; i++) {
      final segment = path[i];
      if (current[segment] is! Map<String, dynamic>) {
        current[segment] = <String, dynamic>{};
      }
      current = current[segment] as Map<String, dynamic>;
    }

    final last = path.last;
    if (isArrayPush) {
      if (current[last] is List) {
        (current[last] as List).add(value);
      } else {
        current[last] = <dynamic>[value];
      }
    } else if (current.containsKey(last)) {
      if (current[last] is List) {
        (current[last] as List).add(value);
      } else {
        current[last] = [current[last], value];
      }
    } else {
      current[last] = value;
    }
  }
}
