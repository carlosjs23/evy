import 'dart:async';
import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/route.dart';
import 'package:evy/src/router.dart';

typedef Function VoidCallback(Object error);

/// The Evy Application.
/// TODO: Lazy router initialization.
class Evy {
  HttpServer _server;
  Router _router;

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

  /// Serves as proxy to the [Router] route method.
  Route route(dynamic path) {
    return _router.route(path);
  }

  /// Allows an external [Router] to be passed for usage in the app.
  /// Also serves as proxy to the [Router] use method.
  void use({dynamic path, Callback callback, Router router}) {
    if (router != null) {
      _router = router;
    } else if (callback != null) {
      _router.use(path: path, callback: callback);
    } else {
      throw Exception('Please register either middleware or a router');
    }
  }
}
