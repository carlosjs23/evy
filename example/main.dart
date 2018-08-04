import 'package:evy/evy.dart';

void main() {
  var app = Evy();

  //Routes can have a callback and one or more middlewares.
  app.get(path: '/greet/:name', callback: sayHello, middlewares: [checkName, changeName]);

  //Path can be a RegExp, ie this route match /evy, /evyhi, /whateverevy, etc.
  app.get(path: RegExp('/.*evy'), callback: sayHello);

  //Path can be too a List of Strings,  this will match /users, /user and /client.
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
  if (req.params['name'] != null) {
    res.send('Hello ${req.params['name']}');
  } else {
    res.send('Hello');
  }
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