import 'dart:io';

class Response {
  Response();
  HttpResponse _httpResponse;
  bool _closed = false;
  bool get closed => _closed;

  void send(Object data) {
    _httpResponse.write(data);
    _httpResponse.close();
    _closed = true;
  }

  static Response from(HttpResponse httpResponse) {
    Response newResponse = Response();
    newResponse._httpResponse = httpResponse;
    return newResponse;
  }
}
