import 'dart:io';

import 'package:evy/route.dart';

typedef Function VoidCallback(Object error);
typedef void RouteCallback(HttpRequest request, HttpResponse response);

class Evy {
  HttpServer _server;
  List<Route> _routes = List<Route>();

  void listen(
      {String host: 'localhost', int port: 9710, VoidCallback callback}) async {
    await HttpServer.bind(
      host,
      port,
    ).then((HttpServer server) {
      _server = server;
      callback(null);
      _server.listen((HttpRequest request) {
        _handleRequest(request);
      });
    }).catchError((error) {
      callback(error);
    });
  }

  void _handleRequest(HttpRequest request) {
    Route route = _routes.firstWhere((Route route) => route.match(request),
        orElse: () => null);
    if (route != null) {
      route.callback(request, request.response);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
      request.response.close();
    }
  }

  void get({String path, RouteCallback callback}) {
    Route _route = _routes.firstWhere((Route route) => route.path == path,
        orElse: () => null);
    if (_route == null) {
      Route newRoute = Route('GET', path, callback);
      _routes.add(newRoute);
    }
  }
}
