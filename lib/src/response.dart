import 'dart:io';

/// Wrapper around the [HttpResponse] class for convenience.
class Response {
  HttpResponse _httpResponse;
  bool _closed = false;

  Response([HttpResponse existingResponse]) {
    this._httpResponse = existingResponse;
  }

  bool get closed => _closed;

  void addHeader(String name, Object value) {
    _checkResponseClosed();

    _httpResponse.headers.add(name, value);
  }

  void send(Object data) {
    _checkResponseClosed();

    _httpResponse.write(data);
    _finish();
  }

  void statusCode([int statusCode = HttpStatus.ok]) {
    _checkResponseClosed();

    if (statusCode < 100 || statusCode > 600) {
      throw new Exception(
          'Status code $statusCode invalid: out of range [100, 600]');
    }

    _httpResponse.statusCode = statusCode;
  }

  /// This method will throw an exception when called if the response has already
  /// been closed. Call this before running all methods where the request is
  /// being modified, because the exception will bubble up.
  ///
  /// TODO: Create new exception classes extending Exception.
  void _checkResponseClosed() {
    if (closed) {
      throw new Exception(
          'Can\'t modify request after it has already been closed');
    }
  }

  /// Call this when the [HttpResponse] is done being modified, and should
  /// be closed.
  void _finish() {
    _httpResponse.close();
    _closed = true;
  }

  static Response from(HttpResponse httpResponse) {
    return Response(httpResponse);
  }
}
