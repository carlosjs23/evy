import 'package:evy/src/middleware.dart';
import 'package:evy/src/response.dart';

import 'request.dart';

/// The core component responsible for handle route's methods.
class Route {
  final dynamic _path;
  List<String> methods = List<String>();
  List<Middleware> _stack = List<Middleware>();

  Route(this._path);

  /// Start route's stack iteration.
  void dispatch(Request request, Response response, finish) {
    if (_stack.length == 0) {
      return finish();
    }

    int index = 0;

    _runMiddleware(index, request, response);
  }

  /// Adds a GET method to the internal [Route] stack.
  /// Returns the created [Route] for chaining.
  Route get(Callback callback) {
    Middleware middleware =
        Middleware(path: '/', callback: callback);
    methods.add('GET');
    _stack.add(middleware);
    return this;
  }

  /// Adds a POST method to the internal [Route] stack.
  /// Returns the created [Route] for chaining.
  Route post(Callback callback) {
    Middleware middleware =
        Middleware(path: '/', callback: callback);
    methods.add('POST');
    _stack.add(middleware);
    return this;
  }

  /// Iterates through the route's stack trying to match
  /// the incoming request method with each route's method.
  ///
  /// If it match, the callback for the [Route] stored
  /// in the [Middleware] will be called.
  void _runMiddleware(int index, Request request, Response response) {
    /// Defines the next() callback for call it later.
    /// It allows to pass to the next callback when various callbacks are chained.
    ///
    /// ```
    ///  app.route('/greet/:name').get(sayHello).get(storeResult);
    /// ```
    var nextCallback = () {
      _runMiddleware(++index, request, response);
    };

    var finish = () {
      print('FINISH CALLED');
    };

    if (index >= _stack.length) {
      return finish();
    }

    Middleware middleware = _stack[index];

    request.route = this;

    if (!methods.contains(request.method)) {
      return finish();
    }

    middleware.handleRequest(request, response, nextCallback);
  }
}
