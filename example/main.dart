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

void sayHello(HttpRequest req, HttpResponse res) {
  res.write('Hello ${req.uri.pathSegments[1]}');
  res.close();
}

void sayHelloBeatiful(HttpRequest req, HttpResponse res) {
  if (req.uri.pathSegments[3] == 'yes') {
    res.write('Hello ${req.uri.pathSegments[1]} you are a pro');
  } else {
    res.write('Hello ${req.uri.pathSegments[1]}');
  }
  res.close();
}