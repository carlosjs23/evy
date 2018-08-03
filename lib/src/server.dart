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
    Route route = _routes.firstWhere(
        (Route _route) => _route.path == path && _route.method == 'GET',
        orElse: () => null);
    if (route == null) {
      if (middlewares == null) middlewares = List<RouteCallback>();
      Route newRoute = Route('GET', path, callback, middlewares: middlewares);
      _routes.add(newRoute);
    }
  }

  void post({path, RouteCallback callback, middlewares}) {
    Route route = _routes.firstWhere(
        (Route _route) => _route.path == path && _route.method == 'POST',
        orElse: () => null);
    if (route == null) {
      Route newRoute = Route('POST', path, callback, middlewares: middlewares);
      _routes.add(newRoute);
    }
  }
}
