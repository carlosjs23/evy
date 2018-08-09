import 'dart:io';

import 'package:evy/src/route.dart';

/// Wrapper around the [HttpRequest] class for convenience.
class Request {
  HttpRequest _httpRequest;

  Map params;

  Route route;

  Map body;

  Request();

  String get hostname => _httpRequest.uri.host;

  String get ip => _httpRequest.connectionInfo.remoteAddress.address;

  String get method => _httpRequest.method;

  String get originalUrl => _httpRequest.uri.toString();

  String get path => _httpRequest.uri.path;

  String get query => _httpRequest.uri.query;

  Map get queryParams => _httpRequest.uri.queryParameters;

  static Request from(HttpRequest httpRequest) {
    Request newRequest = Request();
    newRequest._httpRequest = httpRequest;
    return newRequest;
  }
}
