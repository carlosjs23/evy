import 'package:evy/evy.dart';
import 'package:evy/src/route.dart';

typedef void Callback(Request req, Response res, void next);

class Middleware {
  final dynamic path;
  final Callback callback;
  final String method;
  Route route;
  Map params;

  Middleware({this.path, this.callback, this.method});

  void handleRequest(Request request, Response response, void next) {
    callback(request, response, next);
  }

  bool match(dynamic path) {
    var match;
    if (path != null) {
      match = _normalize(path);
    }

    if (match == null) {
      return false;
    }

    if ((match['regexp'] as RegExp).hasMatch(path)) {
      return true;
    }

    return false;
  }

  static Map _normalize(dynamic path, {List<String> keys, bool strict: false}) {
    if (keys == null) {
      keys = [];
    }

    if (path is RegExp) {
      return {'regexp': path, 'keys': keys};
    }
    if (path is List) {
      path = '(${path.join('|')})';
    }

    if (!strict) {
      path += '/?';
    }

    path = path.replaceAllMapped(new RegExp(r'(\.)?:(\w+)(\?)?'),
        (Match placeholder) {
      var replace = new StringBuffer('(?:');

      if (placeholder[1] != null) {
        replace.write('\.');
      }

      replace.write('([\\w%+-._~!\$&\'()*,;=:@]+))');

      if (placeholder[3] != null) {
        replace.write('?');
      }

      keys.add(placeholder[2]);

      return replace.toString();
    }).replaceAll('//', '/');
    print({'regexp': new RegExp('^$path\$'), 'keys': keys});
    return {'regexp': new RegExp('^$path\$'), 'keys': keys};
  }

  Map _parseParams(String path, Map routePath) {
    var params = {};
    Match paramsMatch = routePath['regexp'].firstMatch(path);
    for (var i = 0; i < routePath['keys'].length; i++) {
      String param;
      try {
        param = Uri.decodeQueryComponent(paramsMatch[i + 1]);
      } catch (e) {
        param = paramsMatch[i + 1];
      }

      params[routePath['keys'][i]] = param;
    }
    return params;
  }
}
