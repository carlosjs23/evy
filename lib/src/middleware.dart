import 'package:evy/evy.dart';
import 'package:evy/src/route.dart';

typedef void Callback(Request req, Response res, void next);

/// The core component responsible for request match logic, parse params and
/// store the path and the callback of the Requests handled by the [Router].
class Middleware {
  final dynamic path;
  final Callback callback;
  Map params;
  Route route;
  Map _pathRegexp;

  Middleware({this.path, this.callback}) {
    if (path != '*' && path != '/') {
      _pathRegexp = _normalize(path);
    }
  }

  /// Calls the respective callback for this middleware.
  void handleRequest(Request request, Response response, void next) {
    callback(request, response, next);
  }

  /// Request's patch matching logic.
  bool match(dynamic path) {
    bool match;
    if (path != null) {
      if (this.path == '*') {
        return true;
      }

      if (this.path == '/') {
        return true;
      }
      match = _pathRegexp['regexp'].hasMatch(path);
    }

    if (!match) {
      return false;
    }

    params = _parseParams(path, _pathRegexp);

    return true;
  }

  /// Extracts the Params from the given Path and the calculated Regexp.
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

  /// Creates an regexp from a path.
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
    return {'regexp': new RegExp('^$path\$'), 'keys': keys};
  }
}
