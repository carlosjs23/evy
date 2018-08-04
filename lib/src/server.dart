import 'dart:io';

import 'route.dart';

typedef Function VoidCallback(Object error);

class Evy {
  HttpServer _server;
  List<Route> _routes = List<Route>();

  void listen(
      {String host: 'localhost', int port: 9710, VoidCallback callback}) async {
    try {
      _server = await HttpServer.bind(
        host,
        port,
      );
      callback(null);
      _server.listen((HttpRequest request) {
        _handleRequest(request);
      });
    } catch (error) {
      callback(error);
    }
  }

  void _handleRequest(HttpRequest request) {
    Route route = _routes.firstWhere((Route _route) => _route.match(request),
        orElse: () => null);
    if (route != null) {
      route.handleRequest();
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
      request.response.close();
    }
  }

  void get({path, RouteCallback callback, middlewares}) {
    _checkPathIsValid(path);
    if (middlewares == null) middlewares = List<RouteCallback>();
    Route newRoute = Route('GET', path, callback, middlewares: middlewares);
    _routes.add(newRoute);
  }

  void post({path, RouteCallback callback, middlewares}) {
    _checkPathIsValid(path);
    if (middlewares == null) middlewares = List<RouteCallback>();
    Route newRoute = Route('POST', path, callback, middlewares: middlewares);
    _routes.add(newRoute);
  }

  void _checkPathIsValid(path) {
    if (path == null) {
      throw Exception('Can\'t add a route without a path');
    } else if (path is! RegExp && path is! String && path is! List<String>) {
      throw Exception('Path should be a RegExp or String or List<String>');
    }
  }
}
