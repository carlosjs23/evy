import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';

import 'route.dart';


class Router {
  List<Middleware> _stack = List<Middleware>();

  void use({dynamic path, Callback callback}) {
    _checkPathIsValid(path);
    Middleware middleware = Middleware(path: path, callback: callback);
    _stack.add(middleware);
  }

  Route route(dynamic path) {
    _checkPath(path);
    Route route = Route(path);

    Middleware middleware = Middleware(path: path, callback: route.dispatch);
    middleware.route = route;

    _stack.add(middleware);
    return route;
  }

  void _checkPathIsValid(path) {
    if (path != null && path is! RegExp && path is! String && path is! List<String>) {
      throw Exception('Path should be a RegExp or String or List<String>');
    }
  }

  void _checkPath(path) {
    if (path == null) {
      throw Exception('Can\'t add a route without a path');
    }
    _checkPathIsValid(path);
  }

  void handle(HttpRequest httpRequest) {
    Request request = Request.from(httpRequest);
    Response response = Response(httpRequest.response);

    int index = 0;

    var next = () {
      if (index >= _stack.length) {
        return;
      }

      String path = request.path;

      if (path == null) {
        return;
      }

      Middleware middleware;
      Route route;
      bool match = false;

      while (!match && index < _stack.length) {
        middleware = _stack[index++];
        route = middleware.route;
        match = middleware.match(path);

        if (!match) {
          continue;
        }

        if (route == null) {
          continue;
        }

        String method = request.method;
        bool hasMethod = route.methods.contains(method);

        if (!hasMethod) {
          match = false;
          continue;
        }
      }

      if (!match) {
        return;
      }

      if (route != null) {
        request.route = route;
      }

      request.params = middleware.params;

      if (route != null) {
        middleware.handleRequest(request, response, () {});
      } else {
        middleware.handleRequest(request, response, () {});
      }

    };

    next();
  }

}
