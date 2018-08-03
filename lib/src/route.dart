import 'dart:io';

import 'package:evy/src/response.dart';

import 'request.dart';

typedef void VoidCallback();
typedef void RouteCallback(Request request, Response response, VoidCallback next);

class Route {
  final String method;
  final Map path;
  final String _path;
  final callback;
  List<RouteCallback> _middlewares;
  HttpRequest _httpRequest;

  Route(this.method, this._path, this.callback,
      {List<String> keys, middlewares})
      : path = _normalize(_path, keys: keys),
        _middlewares = middlewares;

  bool match(HttpRequest request) {
    _httpRequest = request;
    return ((method == request.method || method == 'MIDDLEWARE') &&
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

  void _runMiddleware(int index, Request request, Response response) {
    var middleware = _middlewares[index];

    var nextCallback = () {
      // If we reached the end obviously don't run the next
      if (_middlewares.last == middleware) {
        // But only call the route's handler if the response
        // has not already been closed by an existing middleware
        if (!response.closed) {
          _finalHandler(request, response);
        }

        return;
      }

      _runMiddleware(++index, request, response);
    };

    middleware(request, response, nextCallback);
  }

  void handleRequest() {
    Request request = Request.from(_httpRequest);
    Response response = Response.from(_httpRequest.response);
    request.route = _path;
    request.params = _parseParams(_httpRequest.uri.path, path);

    if (_middlewares != null && _middlewares.isNotEmpty) {
      _runMiddleware(0, request, response);
    }
  }

  void _finalHandler(Request request, Response response) {
    callback(request, response);
  }
}
