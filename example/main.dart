import 'package:evy/evy.dart';

void main() {
  var app = Evy();

  app.get(path: '/greet/:name', callback: sayHello, middlewares: [checkName, changeName]);

  app.listen(port: 3000, callback: (error) {
    if (error != null) {
      print(error);
    } else {
      print('Server listening on port 3000');
    }
  });
}

void sayHello(Request req, Response res) {
  res.send('Hello ${req.params['name']}');
}

void checkName(Request req, Response res, next) {
  if (req.params['name'] != 'Alberto') {
    res.send('Only Alberto is allowed to use this action');
  }
  next();
}

void changeName(Request req, Response res, next) {
  if (req.params['name'] == 'Alberto') {
    req.params['name'] = 'Carlos';
  }
  next();
}