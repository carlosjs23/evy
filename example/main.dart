import 'package:evy/evy.dart';

void main() {
  var app = Evy();
  var router = Router();

  //router.route('*').get(sayHello);

  app.use(router: router);

  app.use(path: '*', callback: alwaysClose);

  //router.route('/greet/:name').get(sayHello).post(sayHello);

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

void sayHello(Request req, Response res, next) {
  print(req.path);
  res.send('Hello');
}

void alwaysClose(Request req, Response res, next) {
  res.send('CLOSED');
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
