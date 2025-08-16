# Evy

[![Gitter chat](https://badges.gitter.im/carlosjs23/Evy.png)](https://gitter.im/evy-dart/evy)

Evy is a modern async-first Dart Web Framework with an ExpressJS-like API, featuring non-blocking I/O operations.

## Getting Started

For start using Evy in your project you need to clone this repo and add it to dependencies section in your pubspec.yaml file:

```yaml
# pubspec.yaml
name: example_app
description: My app

dependencies:
 evy: 
    path: /path/to/evy
```

### Prerequisites

* [Dart 2 SDK](https://www.dartlang.org/tools/sdk#install)
 
## Example code
 
```dart
import 'package:evy/evy.dart';

void main() {
  var app = Evy();

  /// Add body parsing middleware for JSON and form data
  app.use(handler: BodyParser.json());
  app.use(handler: BodyParser.urlencoded());

  /// This middleware will match all routes.
  app.use(handler: logRequest);

  /// This middleware will be called only for '/greet/:name' routes.
  app.use(path: '/greet/:name', handler: checkName);

  /// This middleware will be called only for '/greet/:name' routes.
  /// It will be executed after checkName middleware.
  app.use(path: '/greet/:name', handler: changeName);

  /// Routes can have async handlers for processing requests.
  app.get(path: '/greet/:name', handler: sayHello);
  app.post(path: '/users', handler: createUser);

  /// Path can be a RegExp, this route will match /evy, /evyhi, /whateverevy... .
  app.get(path: RegExp('/.*evy'), handler: sayHello);

  /// Path can be a List of Strings, this will match /users, /user and /client.
  app.get(path: ['/users', '/user', '/client'], handler: sayHello);

  app.listen(
      port: 3000,
      callback: (error) {
        if (error != null) {
          print(error);
        } else {
          print('Server listening on port 3000');
        }
      });
}

/// All middleware and route handlers are async
Future<void> changeName(Request req, Response res, next) async {
  if (req.params?['name'] == 'Alberto') {
    req.params!['name'] = 'Carlos';
  }
  await next();
}

Future<void> checkName(Request req, Response res, next) async {
  if (req.params?['name'] != 'Alberto') {
    res.send('Only Alberto is allowed to use this action');
  } else {
    await next();
  }
}

Future<void> logRequest(Request req, Response res, next) async {
  /// Do your logging stuff and then call next()
  print('${req.ip} - - [${DateTime.now()}] "${req.method} ${req.originalUrl}"');
  await next();
}

Future<void> sayHello(Request req, Response res, next) async {
  if (req.params?['name'] != null) {
    res.send('Hello ${req.params!['name']}');
  } else {
    res.send('Hello');
  }
}

/// Example POST handler that uses parsed request body
Future<void> createUser(Request req, Response res, next) async {
  if (req.body != null) {
    final name = req.body!['name'];
    final email = req.body!['email'];
    
    // Simulate async database operation
    await Future.delayed(Duration(milliseconds: 100));
    
    res.send('User created: $name ($email)');
  } else {
    res.status(400);
    res.send('Missing request body');
  }
}
```

## Features

 - [X] **Async-first architecture** - Non-blocking I/O operations and concurrent request handling
 - [X] **Built-in body parsing** - JSON and URL-encoded form data parsing
 - [X] **HTTP methods** - GET, POST, PUT, DELETE support
 - [X] **Request/Response wrappers** - Clean API for handling HTTP requests
 - [X] **Middleware system** - Both global and route-specific middleware
 - [X] **Sub-applications** - Mount apps with ``app.use(path: '/api', app: apiApp)``
 - [X] **Flexible routing** - String, RegExp, and List path matching
 - [X] **Route parameters** - Dynamic URL parameters (e.g., ``/users/:id``)

### Body Parser Examples

```dart
// JSON requests
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@example.com"}'

// Form data requests  
curl -X POST http://localhost:3000/users \
  -d "name=John&email=john@example.com"
```

### Todo
 - [ ] Routes group.
 - [ ] Publish package to Dart Packages.
 - [ ] Testing framework.
 - [ ] Logo design.
 