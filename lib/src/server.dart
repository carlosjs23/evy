import 'dart:io';

import 'package:evy/src/middleware.dart';
import 'package:evy/src/router.dart';

typedef Function VoidCallback(Object error);

class Evy {
  HttpServer _server;
  Router _router = Router();

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

  void _handleRequest(HttpRequest httpRequest) {
    _router.handle(httpRequest);
  }

  void use({dynamic path, Callback callback, Router router}) {
    if (router != null) {
      _router = router;
    }
    _router.use(path: path, callback: callback);
  }

}