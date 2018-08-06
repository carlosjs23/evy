import 'package:evy/evy.dart';
import 'package:evy/src/route.dart';

typedef void Callback(Request req, Response res, void next);

class Middleware {
  final dynamic path;
  final Callback callback;
  final String method;
  Route route;

  Middleware({this.path, this.callback, this.method});

  void handleRequest(Request request, Response response, void next) {
    callback(request, response, next);
  }

}