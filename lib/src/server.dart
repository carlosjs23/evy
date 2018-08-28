import 'dart:async';
import 'dart:io';

import 'package:evy/src/router/route.dart';
import 'package:evy/src/router/router.dart';

typedef Function VoidCallback(Object error);

/// The Evy Application.
class Evy {
  HttpServer _server;

  /// TODO: Lazy router initialization.
  Router _router = Router();

  Router get router => _router;

  /// Serves as proxy to the [Router] delete method.
  Route delete({dynamic path, dynamic handler}) {
    return _router.delete(path: path, handler: handler);
  }

  /// Serves as proxy to the [Router] get method.
  Route get({dynamic path, dynamic handler}) {
    return _router.get(path: path, handler: handler);
  }

  /// Starts a [HttpServer] defaulting localhost:9710 or
  /// at the user defined address:port.
  Future<void> listen(
      {String host: 'localhost', int port: 9710, VoidCallback callback}) async {
    try {
      _server = await HttpServer.bind(
        host,
        port,
      );
      if (callback != null) callback(null);
      _server.listen((HttpRequest request) {
        _router.handle(request);
      });
      return null;
    } catch (error) {
      if (callback != null) callback(error);
      throw error;
    }
  }

  /// Serves as proxy to the [Router] post method.
  Route post({dynamic path, dynamic handler}) {
    return _router.post(path: path, handler: handler);
  }

  /// Serves as proxy to the [Router] put method.
  Route put({dynamic path, dynamic handler}) {
    return _router.put(path: path, handler: handler);
  }

  /// Serves as proxy to the [Router] route method.
  Route route(dynamic path) {
    return _router.route(path);
  }

  /// Serves as proxy to the [Router] use method.
  void use({dynamic path, dynamic handler}) {
    if (path == null) {
      path = '/';
    }
    _router.use(path: path, handler: handler);
  }
}
