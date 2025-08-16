import 'package:evy/evy.dart';

void main() {
  var app = Evy();

  /// Add body parsing middleware for JSON
  app.use(handler: BodyParser.json());

  /// Add body parsing middleware for URL-encoded forms
  app.use(handler: BodyParser.urlencoded());

  /// Add async delay middleware to simulate database operations
  app.use(handler: simulateAsyncOperation);

  /// This middleware will match all routes.
  app.use(handler: logRequest);

  /// This middleware will be called only for '/greet/:name' routes.
  app.use(path: '/greet/:name', handler: checkName);

  /// This middleware will be called only for '/greet/:name' routes.
  /// It will be executed after checkName middleware.
  app.use(path: '/greet/:name', handler: changeName);

  /// Routes can have a callback for process the request.
  app.get(path: '/greet/:name', handler: sayHello);

  /// POST route to demonstrate body parsing
  app.post(path: '/users', handler: createUser);

  /// POST route to demonstrate JSON body parsing
  app.post(path: '/api/users', handler: createUserJson);

  /// Test routes for async behavior
  app.get(path: '/slow', handler: slowAsyncHandler);
  app.get(path: '/fast', handler: fastHandler);
  app.get(path: '/database', handler: simulateDatabaseQuery);
  app.get(path: '/concurrent-test', handler: concurrentTestHandler);

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
          print('');
          print('Body Parser Tests:');
          print(
              '  curl -X POST http://localhost:3000/users -d "name=John&email=john@example.com"');
          print(
              '  curl -X POST http://localhost:3000/api/users -H "Content-Type: application/json" -d \'{"name":"Jane","email":"jane@example.com"}\'');
          print('');
          print('Async Framework Tests:');
          print('  curl http://localhost:3000/fast    # Fast response');
          print('  curl http://localhost:3000/slow    # 2 second delay');
          print('  curl http://localhost:3000/database # Simulate DB query');
          print(
              '  curl http://localhost:3000/concurrent-test # Multiple async operations');
          print('');
          print('Concurrent Test (run these simultaneously):');
          print(
              '  curl http://localhost:3000/slow & curl http://localhost:3000/fast & curl http://localhost:3000/slow &');
        }
      });
}

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

Future<void> createUser(Request req, Response res, next) async {
  if (req.body != null) {
    final name = req.body!['name'];
    final email = req.body!['email'];
    res.send('User created: $name ($email)');
  } else {
    res.status(400);
    res.send('No form data received');
  }
}

Future<void> createUserJson(Request req, Response res, next) async {
  if (req.body != null) {
    final name = req.body!['name'];
    final email = req.body!['email'];
    res.send('User created from JSON: $name ($email)');
  } else {
    res.status(400);
    res.send('No JSON data received');
  }
}

/// Middleware that simulates async I/O operations (like database queries)
Future<void> simulateAsyncOperation(Request req, Response res, next) async {
  final startTime = DateTime.now();
  print('[AsyncMiddleware] Starting async operation for ${req.path}');

  // Simulate async I/O operation (database lookup, file read, API call, etc.)
  await Future.delayed(Duration(milliseconds: 100));

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime).inMilliseconds;
  print('[AsyncMiddleware] Completed async operation in ${duration}ms');

  // Add timing info to request for debugging
  req.params ??= {};
  req.params!['asyncDuration'] = duration;

  await next();
}

/// Handler that demonstrates slow async operations
Future<void> slowAsyncHandler(Request req, Response res, next) async {
  final startTime = DateTime.now();
  print('[SlowHandler] Starting slow operation...');

  // Simulate a slow database query or external API call
  await Future.delayed(Duration(seconds: 2));

  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime).inMilliseconds;

  print('[SlowHandler] Completed slow operation in ${totalDuration}ms');
  res.send(
      'Slow response completed in ${totalDuration}ms (middleware: ${req.params?['asyncDuration']}ms)');
}

/// Handler that responds quickly to test concurrent handling
Future<void> fastHandler(Request req, Response res, next) async {
  final startTime = DateTime.now();
  print('[FastHandler] Processing fast request...');

  // Minimal processing time
  await Future.delayed(Duration(milliseconds: 10));

  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime).inMilliseconds;

  print('[FastHandler] Completed fast request in ${totalDuration}ms');
  res.send(
      'Fast response completed in ${totalDuration}ms (middleware: ${req.params?['asyncDuration']}ms)');
}

/// Simulate multiple database operations
Future<void> simulateDatabaseQuery(Request req, Response res, next) async {
  final startTime = DateTime.now();
  print('[DatabaseHandler] Starting database simulation...');

  // Simulate multiple async database operations
  print('[DatabaseHandler] Querying users table...');
  await Future.delayed(Duration(milliseconds: 300));

  print('[DatabaseHandler] Querying permissions table...');
  await Future.delayed(Duration(milliseconds: 200));

  print('[DatabaseHandler] Querying audit log...');
  await Future.delayed(Duration(milliseconds: 100));

  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime).inMilliseconds;

  print(
      '[DatabaseHandler] Database operations completed in ${totalDuration}ms');
  res.send(
      'Database simulation completed in ${totalDuration}ms (middleware: ${req.params?['asyncDuration']}ms)');
}

/// Handler that performs multiple concurrent async operations
Future<void> concurrentTestHandler(Request req, Response res, next) async {
  final startTime = DateTime.now();
  print('[ConcurrentHandler] Starting concurrent operations...');

  // Run multiple async operations concurrently
  final futures = [
    _simulateApiCall('UserService', 400),
    _simulateApiCall('PaymentService', 300),
    _simulateApiCall('NotificationService', 200),
    _simulateApiCall('AuditService', 100),
  ];

  final results = await Future.wait(futures);

  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime).inMilliseconds;

  print(
      '[ConcurrentHandler] All concurrent operations completed in ${totalDuration}ms');
  res.send(
      'Concurrent operations completed in ${totalDuration}ms:\n${results.join('\n')}\n(middleware: ${req.params?['asyncDuration']}ms)');
}

/// Helper function to simulate API calls
Future<String> _simulateApiCall(String serviceName, int delayMs) async {
  final startTime = DateTime.now();
  print('[ConcurrentHandler] Calling $serviceName...');

  await Future.delayed(Duration(milliseconds: delayMs));

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime).inMilliseconds;

  print('[ConcurrentHandler] $serviceName responded in ${duration}ms');
  return '$serviceName: ${duration}ms';
}
