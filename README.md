# Evy

[![Gitter chat](https://badges.gitter.im/carlosjs23/Evy.png)](https://gitter.im/evy-dart/evy)

Evy is a Dart 2 Web Framework, with an ExpressJS like API.

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

  /// This middleware will match all routes.
  app.use(path: '*', callback: logRequest);

  /// This middleware will be called only for '/greet/:name' routes.
  app.use(path: '/greet/:name', callback: checkName);

  /// This middleware will be called only for '/greet/:name' routes.
  /// It will be executed after checkName middleware.
  app.use(path: '/greet/:name', callback: changeName);
  
  /// Or just pass the middleware callbacks as a list.
  app.use(path: '/greet/:name', callback: [checkName, changeName]);

  ///Routes can have a callback for process the request.
  app.get(path: '/greet/:name', callback: sayHello);

  ///Path can be a RegExp, this route will match /evy, /evyhi, /whateverevy... .
  app.get(path: RegExp('/.*evy'), callback: sayHello);

  ///Path can be a List of Strings, this will match /users, /user and /client.
  app.get(path: ['/users', '/user', '/client'], callback: sayHello);

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

void changeName(Request req, Response res, next) {
  if (req.params['name'] == 'Alberto') {
    req.params['name'] = 'Carlos';
  }
  next();
}

void checkName(Request req, Response res, next) {
  if (req.params['name'] != 'Alberto') {
    res.send('Only Alberto is allowed to use this action');
  } else {
    next();
  }
}

void logRequest(Request req, Response res, next) {
  /// Do your logging stuff and then call next()
  print('${req.ip} - - [${DateTime.now()}] "${req.method} ${req.originalUrl}"');
  next();
}

void sayHello(Request req, Response res, next) {
  if (req.params['name'] != null) {
    res.send('Hello ${req.params['name']}');
  } else {
    res.send('Hello');
  }
}
```

### Todo
 - [X] Implement basic HTTP methods (~~POST~~, PUT, etc).
 - [X] Create Request and Response wrappers.
 - [X] Per Route Middlewares.
 - [X] Global Middlewares.
 - [ ] Sub-apps ``app.use(path: '/billing', app: billingApp)``.
 - [ ] ~~Serve static files~~ (Use a package instead).
 - [ ] ~~Content body parsing~~ (Use a package instead).
 - [ ] Routes group.
 - [ ] Publish package to Dart Packages.
 - [ ] Testing.
 - [ ] Logo design.
 