# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-08-16

### Major Changes - Async-First Architecture

This release represents a complete architectural transformation from synchronous to async-first design, bringing Evy in line with modern web framework patterns.

### Added
- **Built-in Body Parser**: JSON and URL-encoded form data parsing via `BodyParser` middleware
  - `BodyParser.json()` - Parse JSON request bodies
  - `BodyParser.urlencoded()` - Parse form data
  - `BodyParser.text()` - Parse text bodies
- **Async-first middleware system** - All middleware and route handlers are now `Future<void>`
- **Concurrent request handling** - Non-blocking I/O operations
- **Enhanced Request class** - Added `body`, `headers`, `contentType`, and `httpRequest` properties
- **Response.status() method** - Convenience method for setting status codes

### Changed
- **BREAKING**: All middleware signatures changed from `void` to `Future<void>`
- **BREAKING**: All `next()` calls must now be `await next()`
- **BREAKING**: Route handlers must be async: `Future<void> handler(Request, Response, next)`
- **Router middleware execution** - Now properly handles async operations
- **Error handling** - Async error propagation throughout middleware stack
- **Example application** - Updated to demonstrate async patterns and body parsing

### Fixed
- **POST route registration bug** - Router.post() was incorrectly calling .get() internally
- **Middleware execution flow** - Proper async await chains prevent hanging requests
- **Request body parsing** - No longer blocks the event loop

### Performance
- **Concurrent operations** - Multiple requests can now be processed simultaneously
- **Non-blocking I/O** - Async operations don't block other requests
- **Efficient body parsing** - Streaming body parser with configurable limits

### Migration Guide

**Before (v0.0.5):**
```dart
void myMiddleware(Request req, Response res, next) {
  // Sync processing
  next();
}
```

**After (v0.1.0):**
```dart
Future<void> myMiddleware(Request req, Response res, next) async {
  // Async processing
  await someAsyncOperation();
  await next();
}

// Add body parsing
app.use(handler: BodyParser.json());
app.use(handler: BodyParser.urlencoded());
```

## [0.0.5] - Previous Release

* **Breaking change.** Route callback param has been renamed to handler. 
* Sub-app support via app.use()

## [0.0.4] - Previous Release

* Fix request params being lost in middlewares.
* Docs

## [0.0.3] - Previous Release

* Per route middleware
* Response object

## [0.0.2] - Previous Release

* Request object
* Basic HTTP methods 

## [0.0.1] - Previous Release

* Initial Release