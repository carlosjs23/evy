import 'dart:io';

class Request {
  HttpRequest _httpRequest;
  Map params;

  // The route can be an RegExp, a List or an String
  dynamic route;

  // TODO: Implement body parser.
  Map body;

  Request();

  String get hostname => _httpRequest.uri.host;

  String get ip => _httpRequest.connectionInfo.remoteAddress.address;

  String get method => _httpRequest.method;

  String get path => _httpRequest.uri.path;

  String get query => _httpRequest.uri.query;

  Map get queryParams => _httpRequest.uri.queryParameters;

  static Request from(HttpRequest httpRequest) {
    Request newRequest = Request();
    newRequest._httpRequest = httpRequest;
    return newRequest;
  }
}
