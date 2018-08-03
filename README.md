# Evy

[![Gitter chat](https://badges.gitter.im/carlosjs23/Evy.png)](https://gitter.im/evy-dart/evy)

Evy is a Dart 2 Web Framework, with an ExpressJS like API.

*Note: At the moment the API is unfinished and it's just a proof of concept (thats why it's not yet published to Dart Packages).*

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

  app.get(path: '/greet/:name', callback: sayHello, middlewares: [checkName, changeName]);

  app.get(path: RegExp('/.*evy'), callback: sayHello);

  app.get(path: ['/users', '/user', '/client'], callback: sayHello);

  app.listen(port: 3000, callback: (error) {
    if (error != null) {
      print(error);
    } else {
      print('Server listening on port 3000');
    }
  });
}

void sayHello(Request req, Response res, next) {
  if (req.params['name'] != null)
    res.send('Hello ${req.params['name']}');
  else
    res.send('Hello');
}

void checkName(Request req, Response res, next) {
  if (req.params['name'] != 'Alberto') {
    res.send('Only Alberto is allowed to use this action');
  } else {
    next();
  }
}

void changeName(Request req, Response res, next) {
  if (req.params['name'] == 'Alberto') {
    req.params['name'] = 'Carlos';
  }
  next();
}
```

### Todo
 - [ ] Implement basic HTTP methods (~~POST~~, PUT, etc).
 - [X] Create Request and Response wrappers(Partially done).
 - [ ] Serve static files.
 - [X] Per Route Middlewares.
 - [ ] Global Middlewares.
 - [ ] Content body parsing.
 - [ ] Routes group.
 - [ ] Publish package to Dart Packages.
 - [ ] Testing.
 - [ ] Logo design.
 