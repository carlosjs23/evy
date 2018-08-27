import 'dart:io';

import 'package:evy/src/request.dart';
import 'package:evy/src/response.dart';
import 'package:evy/src/server.dart';

import 'middleware.dart';
import 'route.dart';

/// The core component responsible for maintaining the middleware stack
/// and handle the requests that comes from the app.
class Router {
  final List<Middleware> _stack = List<Middleware>();

  Route delete({dynamic path, dynamic callback}) {
    Route _route = route(path).delete(callback);
    return _route;
  }

  Route get({dynamic path, dynamic callback}) {
    Route _route = route(path).get(callback);
    return _route;
  }

  /// Pass every request coming from the app to start processing it.
  void handle(HttpRequest httpRequest) {
    if (_stack.length == 0) {
      return;
    }

    Request request = Request.from(httpRequest);
    Response response = Response(httpRequest.response);

    _runMiddleware(0, request, response);
  }

  Route post({dynamic path, dynamic callback}) {
    Route _route = route(path).get(callback);
    return _route;
  }

  Route put({dynamic path, dynamic callback}) {
    Route _route = route(path).put(callback);
    return _route;
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
  void use({dynamic path, dynamic handler}) {
    _checkPathIsValid(path);
    if (handler is List<Callback>) {
      handler.forEach((_callback) {
        Middleware middleware = Middleware(path: path, callback: _callback);
        _stack.add(middleware);
      });
    } else if (handler is Callback) {
      Middleware middleware = Middleware(path: path, callback: handler);
      _stack.add(middleware);
    } else if (handler is Router) {
      handler._stack.forEach((_middleware) {
        //_middleware.path = path + _middleware.path;
        Middleware newMiddleware = Middleware(path: _middleware.path, callback: _middleware.callback);
        newMiddleware.route = _middleware.route;
        _stack.add(newMiddleware);
      });
    } else if (handler is Evy) {
      handler.router._stack.forEach((_middleware) {
        //_middleware.path = path + _middleware.path;
        Middleware newMiddleware = Middleware(path: _middleware.path, callback: _middleware.callback);
        newMiddleware.route = _middleware.route;
        _stack.add(newMiddleware);
      });
    } else {
      throw Exception('Please register either middleware or a router');
    }
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
      return;
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

    /// TODO: Merge params.
    if (request.params == null) {
      request.params = middleware.params;
    }

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
