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