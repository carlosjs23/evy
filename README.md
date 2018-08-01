# Evy

Evy is a Dart 2 Web Framework, with an ExpressJS like API.

*Note: At the moment the API is unfinished and it's just a proof of concept.*

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
import 'dart:io';
import 'package:evy/evy.dart';

void main() {
  var app = Evy();
  
  app.get(path: '/greet/:name', callback: sayHello);

  app.get(path: '/greet/:name/beatiful/:question', callback: sayHelloBeatiful);
  
  app.listen(port: 3000, callback: (error) {
    if (error != null) {
      print('An error has ocurred: ${error}');
    } else {
      print('Server listening on port 3000');
    }
  });
}

void sayHello(Request req, HttpResponse res) {
  res.write('Hello ${req.params['name']}');
  res.close();
}

void sayHelloBeatiful(Request req, HttpResponse res) {
  if (req.params['question'] == 'yes') {
    res.write('Hello ${req.params['name']} you are a pro');
  } else {
    res.write('Hello ${req.params['name']}');
  }
  res.close();
}
```

### Todo:
 - [ ] Implement basic HTTP methods (~~POST~~, PUT, etc).
 - [ ] Create ~~Request~~ and Response wrappers.
 - [ ] Serve static files.
 - [ ] Middlewares.
 - [ ] Content body parsing.
 