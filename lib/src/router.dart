import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';

import 'route.dart';

class Router {
  List<Middleware> _stack = List<Middleware>();

  void handle(HttpRequest httpRequest) {
    Request request = Request.from(httpRequest);
    Response response = Response(httpRequest.response);

    if (_stack.length == 0) {
      return;
    }

    _runMiddleware(0, request, response);
  }

  Route route(dynamic path) {
    _checkPath(path);
    Route route = Route(path);

    Middleware middleware = Middleware(path: path, callback: route.dispatch);
    middleware.route = route;

    _stack.add(middleware);
    print('Router stack: ${_stack.length}');
    return route;
  }

  void use({dynamic path, Callback callback}) {
    _checkPathIsValid(path);
    Middleware middleware = Middleware(path: path, callback: callback);
    _stack.add(middleware);
  }

  void _checkPath(path) {
    if (path == null) {
      throw Exception('Can\'t add a route without a path');
    }
    _checkPathIsValid(path);
  }

  void _checkPathIsValid(path) {
    if (path != null &&
        path is! RegExp &&
        path is! String &&
        path is! List<String>) {
      throw Exception('Path should be a RegExp or String or List<String>');
    }
  }

  void _runMiddleware(int index, Request request, Response response) {
    var nextCallback = () {
      _runMiddleware(++index, request, response);
    };

    var finish = () {
      print('FINISH CALLED');
    };

    if (index >= _stack.length) {
      return finish();
    }
    String path = request.path;

    if (path == null) {
      return finish();
    }

    Middleware middleware = _stack[index];
    Route route = middleware.route;
    bool match = middleware.match(path);

    if (!match) {
      return nextCallback();
    }

    request.params = middleware.params;

    if (route == null) {
      return middleware.handleRequest(request, response, nextCallback);
    }

    if (route != null) {
      String method = request.method;
      bool hasMethod = route.methods.contains(method);

      if (!hasMethod) {
        return nextCallback();
      }

      request.route = route;
      route.dispatch(request, response, finish);
    }
  }
}
