import 'dart:io';

import 'package:evy/src/request.dart';

typedef void RouteCallback(Request request, HttpResponse response);

class Route {
  final String method;
  final Map path;
  final String _path;
  final callback;

  Route(this.method, this._path, this.callback, {List<String> keys})
      : path = _normalize(_path, keys: keys);

  bool match(HttpRequest request) {
    return (method == request.method &&
        (path['regexp'] as RegExp).hasMatch(request.uri.path));
  }

  static Map _normalize(dynamic path, {List<String> keys, bool strict: false}) {
    if (keys == null) {
      keys = [];
    }

    if (path is RegExp) {
      return {'regexp': path, 'keys': keys};
    }
    if (path is List) {
      path = '(${path.join('|')})';
    }

    if (!strict) {
      path += '/?';
    }

    path = path.replaceAllMapped(new RegExp(r'(\.)?:(\w+)(\?)?'),
        (Match placeholder) {
      var replace = new StringBuffer('(?:');

      if (placeholder[1] != null) {
        replace.write('\.');
      }

      replace.write('([\\w%+-._~!\$&\'()*,;=:@]+))');

      if (placeholder[3] != null) {
        replace.write('?');
      }

      keys.add(placeholder[2]);

      return replace.toString();
    }).replaceAll('//', '/');

    return {'regexp': new RegExp('^$path\$'), 'keys': keys};
  }

  Map _parseParams(String path, Map routePath) {
    var params = {};
    Match paramsMatch = routePath['regexp'].firstMatch(path);
    for (var i = 0; i < routePath['keys'].length; i++) {
      String param;
      try {
        param = Uri.decodeQueryComponent(paramsMatch[i + 1]);
      } catch (e) {
        param = paramsMatch[i + 1];
      }

      params[routePath['keys'][i]] = param;
    }
    return params;
  }

  void handleRequest(HttpRequest httpRequest) {
    Request request = Request.from(httpRequest);
    request.route = _path;
    request.params = _parseParams(httpRequest.uri.path, path);
    callback(request, httpRequest.response);
  }
}
