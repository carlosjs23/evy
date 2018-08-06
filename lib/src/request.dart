import 'dart:io';

import 'package:evy/src/route.dart';

class Request {
  HttpRequest _httpRequest;
  Map params;

  Route route;

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
