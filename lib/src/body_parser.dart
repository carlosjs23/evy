import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';

class BodyParser {
  /// Middleware for parsing JSON request bodies
  static Function json({int? limit}) {
    return (Request req, Response res, Function next) async {
      if (req.method == 'GET' || req.method == 'HEAD') {
        return await next();
      }

      final contentType = req.headers.contentType;
      if (contentType == null || contentType.mimeType != 'application/json') {
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

      final contentType = req.headers.contentType;
      if (contentType == null ||
          contentType.mimeType != 'application/x-www-form-urlencoded') {
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

      final contentType = req.headers.contentType;
      if (contentType == null || !contentType.mimeType.startsWith('text/')) {
        return await next();
      }

      try {
        final body = await _readBody(req.httpRequest, limit);
        req.body = {'raw': body};
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

    final completer = Completer<String>();
    final chunks = <List<int>>[];
    int totalBytes = 0;

    request.listen(
      (List<int> chunk) {
        totalBytes += chunk.length;
        if (limit != null && totalBytes > limit) {
          throw Exception('Request body too large');
        }
        chunks.add(chunk);
      },
      onDone: () {
        final bytes = chunks.expand((chunk) => chunk).toList();
        final body = utf8.decode(bytes);
        completer.complete(body);
      },
      onError: (error) {
        completer.completeError(error);
      },
    );

    return completer.future;
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

      if (extended && key.contains('[') && key.contains(']')) {
        _setNestedValue(result, key, value);
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

  /// Set nested values for extended URL encoding (e.g., user[name]=John)
  static void _setNestedValue(
      Map<String, dynamic> result, String key, String value) {
    final bracketIndex = key.indexOf('[');
    if (bracketIndex == -1) {
      result[key] = value;
      return;
    }

    final baseKey = key.substring(0, bracketIndex);
    final remainingKey = key.substring(bracketIndex + 1, key.length - 1);

    result[baseKey] ??= <String, dynamic>{};

    if (remainingKey.isEmpty) {
      if (result[baseKey] is List) {
        (result[baseKey] as List).add(value);
      } else if (result[baseKey] is Map) {
        final list = <dynamic>[];
        if ((result[baseKey] as Map).isNotEmpty) {
          list.add(result[baseKey]);
        }
        list.add(value);
        result[baseKey] = list;
      } else {
        result[baseKey] = [value];
      }
    } else {
      if (result[baseKey] is! Map) {
        result[baseKey] = <String, dynamic>{};
      }
      _setNestedValue(
          result[baseKey] as Map<String, dynamic>, '$remainingKey]', value);
    }
  }
}
