# Evy Roadmap

Evy's goal is **not** full ExpressJS parity. Express's API is the ergonomic
north star — routing, middleware, `req`/`res` — but part of its surface exists
to work around Node.js-era constraints that Dart doesn't have. Evy targets:

> **Express's routing and middleware ergonomics, complete universal HTTP
> support, and a Dart-native layer (types, isolates, WebSockets, shelf
> interop) that Express cannot offer.**

Roughly: ~70% of the Express checklist, plus a handful of features Express
doesn't have. Each milestone below is shippable on its own. Everything is
developed test-first against the suite introduced in v0.1.0.

---

## v0.2.0 — HTTP correctness

The features every web framework needs regardless of language. Today a
request that matches no route **hangs forever**; this milestone makes Evy
safe to put in front of real traffic.

### Routing & lifecycle
- [ ] **Default 404 handler** — when the middleware stack is exhausted
      without a response, send `404 Not Found` instead of hanging the
      connection.
- [ ] **Error-handling middleware** — an explicit, typed API instead of
      Express's arity-detection trick (counting `(err, req, res, next)`
      parameters is JavaScript reflection that Dart cannot do, and shouldn't):
      ```dart
      app.onError((Object error, Request req, Response res) async { ... });
      // optionally typed per exception:
      app.onError<ValidationException>((e, req, res) async { ... });
      ```
      Handlers and middleware can surface errors by throwing; the router
      routes them to the registered handler, falling back to a default 500
      (with stack trace in development mode).
- [ ] **Remaining HTTP verbs** — `patch()`, `head()`, `options()`, and
      `all()` on both `Evy` and `Route`.
- [ ] **HEAD served by GET routes** — automatic, headers-only response.
- [ ] **Automatic OPTIONS** — respond with the route's `Allow` methods when
      no explicit OPTIONS handler exists.
- [ ] **`next('route')` control flow** — skip the remaining handlers of the
      current route and continue router matching (Dart shape TBD: a value
      passed to `next()` or a dedicated `skipRoute()`).

### Response API
- [ ] **`res.json(Object)`** — serialize with `dart:convert`, set
      `Content-Type: application/json`.
- [ ] **Smarter `res.send()`** — set `Content-Type`/`Content-Length` by
      value type (String → text/html like Express, `List<int>`/bytes →
      application/octet-stream, Map/List → delegate to `res.json`).
- [ ] **Header API** — `res.set(name, value)`, `res.get(name)`,
      `res.type(mime)`, `res.append(name, value)`, `res.vary(header)`.
- [ ] **`res.redirect([status,] url)`** — 302 default, `Location` header.
- [ ] **`res.sendStatus(code)`** — status + canonical reason phrase as body.

## v0.3.0 — Daily-driver features

What an Express user reaches for in the first hour of building a real app.

- [ ] **Static file middleware** — `evy.static(root)`: streaming file
      responses, index files, dotfile policy, cache headers. (Reverses the
      old "use a package instead" stance — parity means shipping it, likely
      via shelf interop below.)
- [ ] **Cookies** — `req.cookies` parsing and `res.cookie(name, value,
      options)` / `res.clearCookie(name)` (dart:io `Cookie` under the hood);
      signed cookies as a follow-up.
- [ ] **Real query parsing** — repeated keys → lists (via
      `queryParametersAll`), optional bracket-nesting reusing the v0.1.0
      extended body parser; exposed as `req.query`.
- [ ] **Request helpers** — `req.get(header)`, `req.is(type)`,
      `req.protocol`, `req.secure`, `req.xhr`, `req.baseUrl`,
      `req.subdomains`.
- [ ] **Trust proxy** — honour `X-Forwarded-For` / `X-Forwarded-Proto` when
      enabled; `req.ip` / `req.ips` correct behind load balancers.
- [ ] **File responses** — `res.sendFile(path)`, `res.download(path,
      [filename])`, `res.attachment()`, streaming with correct MIME types.
- [ ] **`res.raw()` body parser** — binary bodies as bytes; honour request
      charset in text parsers instead of assuming UTF-8.
- [ ] **Router maturity** — `mergeParams` for nested routers (removing the
      long-standing TODO), RegExp/List-safe sub-app mounting (mounting
      currently concatenates path strings and breaks on non-String paths),
      `router.param()` preload hooks, param regex constraints
      (`:id(\d+)`), case-sensitivity and strict-slash options.
- [ ] **Route groups** — carried over from the original TODO list.
- [ ] **`res.locals` / per-request context bag.**

## v0.4.0 — The Dart-native layer

Where Evy stops chasing Express and starts differentiating. These are
features Express core cannot offer, or offers only via external packages
and process managers.

- [ ] **Typed request handling** — lean into the type system instead of
      `dynamic` everywhere:
      - typed param access (`req.paramInt('id')` or declarative binding),
      - `req.bodyAs<T>(T Function(Map) fromJson)`,
      - handler signatures checked at **analysis time** rather than the
        current runtime `is! Callback` throw.
- [ ] **Return-value handlers** — support the shelf-style model alongside
      `res.send`:
      ```dart
      app.get(path: '/users', handler: (req) async => Json(users));
      ```
      Composable, trivially unit-testable, still Express-flavoured.
- [ ] **WebSockets first-class** — `app.ws(path: '/chat', handler: ...)`
      using `dart:io`'s built-in `WebSocketTransformer` (Node needs
      `ws`/socket.io; Dart doesn't).
- [ ] **Server-Sent Events helper** — `res.sse()` streaming API.
- [ ] **Multi-core out of the box** —
      `app.listen(port: 3000, isolates: 4)` using
      `HttpServer.bind(shared: true)` + isolates. No cluster module, no
      external process manager.
- [ ] **Shelf interop adapter** — `app.use(handler: fromShelf(middleware))`
      (and ideally the reverse). One small adapter rents the entire existing
      Dart middleware ecosystem — `shelf_static`, `shelf_web_socket`, CORS,
      rate limiting — instead of reimplementing each package. Strategically
      the highest-leverage item on this roadmap.
- [ ] **Zone-based request context** — `AsyncLocalStorage`-style per-request
      context (request IDs, loggers, current user) via Dart zones.
- [ ] **HTTPS/TLS** — `app.listen(securityContext: ...)` wrapping
      `HttpServer.bindSecure`.
- [ ] **Typed app configuration** — `Evy(EvyConfig(trustProxy: true,
      strictRouting: false, ...))` instead of Express's string-keyed
      `app.set('key', value)` bag: autocompletable, typo-proof, analyzable.

## v0.5.0 and beyond — The long tail

- [ ] **Conditional GET** — ETag generation, `req.fresh` / `req.stale`,
      automatic `304 Not Modified`.
- [ ] **Content negotiation** — `req.accepts()` /
      `acceptsCharsets/Encodings/Languages`, `res.format({...})`.
- [ ] **Range requests** — `req.range()`, partial-content file serving.
- [ ] **HTML convenience** — `res.html(String)`; template rendering stays
      out of core (optional companion package, e.g. mustache-based).
- [ ] **AOT deployment story** — docs and examples for
      `dart compile exe`: single static binary, minimal containers, no
      dependency folder to ship.
- [ ] **Publish to pub.dev** (from the original TODO list).
- [ ] **Logo design** (from the original TODO list).

---

## Non-goals

Deliberately **not** on the roadmap — Node idioms that don't translate to
Dart, or technology Evy has no reason to carry:

- **JSONP** (`res.jsonp`) — a 2010-era CORS workaround; dead technology.
- **View engine registry in core** (`app.engine`, `res.render`) — Dart's
  server niche is APIs and backends for Flutter/web frontends, not
  server-rendered template sites. Covered by `res.html` + optional packages.
- **Arity-detected error middleware** — impossible in Dart and a worse API
  than an explicit typed one; see `app.onError` in v0.2.0.
- **String-keyed settings** (`app.set('trust proxy', 1)`) — replaced by
  typed configuration in v0.4.0.
- **Cluster-style process management** — unnecessary; isolates cover
  multi-core natively (v0.4.0).
