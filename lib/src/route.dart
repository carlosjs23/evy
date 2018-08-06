import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/response.dart';

import 'request.dart';

typedef void RouteCallback(Request request, Response response, void next);

class Route {
  final Map path;
  final dynamic _path;
  List<dynamic> methods;
  HttpRequest _httpRequest;
  List<Middleware> _stack = List<Middleware>();


  Route(this._path, {List<String> keys, List<RouteCallback> middlewares})
      : path = _normalize(_path, keys: keys);

  bool match(HttpRequest request) {
    _httpRequest = request;
    return ((path['regexp'] as RegExp).hasMatch(request.uri.path));
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

  void runMiddleware(int index, Request request, Response response) {
    Middleware middleware = _stack[index];

    if (middleware == null) {
      print('MIDDLEWARE NULL');
    }

    request.route = this;

    var nextCallback = () {
      runMiddleware(++index, request, response);
    };

    middleware.handleRequest(request, response, nextCallback);
  }

  Route get(Callback callback) {
    Middleware middleware = Middleware(method: 'GET', callback: callback);
    _stack.add(middleware);
  }

/*  void handleRequest() {
    Request request = Request.from(_httpRequest);
    Response response = Response.from(_httpRequest.response);
    //request.route = _path;
    request.params = _parseParams(_httpRequest.uri.path, path);

    if (_middlewares != null && _middlewares.isNotEmpty) {
      _runMiddleware(0, request, response);
    } else {
      response.send(
          'Cannot ${request.method.toUpperCase()} ${_httpRequest.uri.path}');
    }
  }*/
}
