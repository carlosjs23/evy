import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';

import 'route.dart';

/// The core component responsible for maintaining the middleware stack
/// and handle the requests that comes from the app.
class Router {
  List<Middleware> _stack = List<Middleware>();

  /// Pass every request coming from the app to start processing it.
  void handle(HttpRequest httpRequest) {
    if (_stack.length == 0) {
      return;
    }

    Request request = Request.from(httpRequest);
    Response response = Response(httpRequest.response);

    _runMiddleware(0, request, response);
  }

  /// Adds a [Route] to the middleware stack and returns it to allow chaining
  /// the methods (Http verbs).
  ///
  /// ```
  /// Router router = Router();
  /// router.route('/users').get(getUsers).post(addUser);
  /// ```
  Route route(dynamic path) {
    _checkPath(path);
    Route route = Route(path);

    Middleware middleware = Middleware(path: path, callback: route.dispatch);
    middleware.route = route;

    _stack.add(middleware);
    return route;
  }

  /// Uses the passed middleware to process requests for the specified path
  /// before the routes.
  ///
  /// ```
  ///  router.use(path: '/greet/:name', callback: checkName);
  ///
  ///  void checkName(Request req, Response res, next) {
  //      if (req.params['name'] != 'Alberto') {
  //        res.send('Only Alberto is allowed to use this action');
  //      } else {
  //        next();
  //      }
  //   }
  /// ```
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

  /// Iterates through the middleware's stack trying to match
  /// the incoming request path with each middleware's path.
  ///
  /// If it match, the callback stored in the middleware will be called.
  /// The callback it's either a middleware function or a router one.
  void _runMiddleware(int index, Request request, Response response) {
    /// Defines the next() callback so we or a route or middleware
    /// can call it to iterate through the middleware's stack.
    var nextCallback = () {
      _runMiddleware(++index, request, response);
    };

    /// TODO: Implement a logger for internal usage.
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

    /// It's a middleware so call it's callback.
    if (route == null) {
      return middleware.handleRequest(request, response, nextCallback);
    }

    /// It's a route so call the route dispatch method.
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
