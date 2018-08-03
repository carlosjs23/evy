import 'dart:io';

class Response {
  HttpResponse _httpResponse;
  bool _closed = false;
  bool get closed => _closed;

  Response([HttpResponse existingResponse]) {
    this._httpResponse = existingResponse;
  }

  /// This method will throw an exception when called if the response has already
  /// been closed. Call this before running all methods where the request is
  /// being modified, because the exception will bubble up.
  /// It may be a good idea in the future to create new exception classes extending
  /// Exception so they can be caught separately or used with `is`
  void _checkResponseClosed() {
    if (closed) {
      throw new Exception('Can\'t modify request after it has already been closed');
    }
  }

  /// Call this when the http response is done being modified, and should
  /// be closed.
  void _finish() {
    _httpResponse.close();
    _closed = true;
  }

  void send(Object data) {
    _checkResponseClosed();

    _httpResponse.write(data);
    _finish();
  }


  void statusCode(int statusCode) {
    _checkResponseClosed();

    if (statusCode < 100 || statusCode > 600) {
      throw new Exception('Status code $statusCode invalid: out of range [100, 600]');
    }

    _httpResponse.statusCode = statusCode;
  }

  static Response from(HttpResponse httpResponse) {
    return Response(httpResponse);
  }
}
