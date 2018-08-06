import 'package:evy/src/middleware.dart';
import 'package:evy/src/response.dart';

import 'request.dart';

typedef void RouteCallback(Request request, Response response, void next);

class Route {
  final dynamic _path;
  List<String> methods = List<String>();
  List<Middleware> _stack = List<Middleware>();

  Route(this._path, {List<String> keys, List<RouteCallback> middlewares});

  void dispatch(Request request, Response response, finish) {
    int index = 0;
    if (_stack.length == 0) {
      finish();
    }

    _runMiddleware(index, request, response);
  }

  Route get(Callback callback) {
    Middleware middleware =
        Middleware(path: '/', method: 'GET', callback: callback);
    methods.add('GET');
    _stack.add(middleware);
    return this;
  }

  Route post(Callback callback) {
    Middleware middleware =
        Middleware(path: '/', method: 'POST', callback: callback);
    methods.add('POST');
    _stack.add(middleware);
    return this;
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

    Middleware middleware = _stack[index];

    request.route = this;

    if (!methods.contains(request.method)) {
      return finish();
    }

    middleware.handleRequest(request, response, nextCallback);
  }
}
