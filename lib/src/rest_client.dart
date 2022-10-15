import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:skein_rest_client/skein_rest_client.dart';

part 'rest_client_registry.dart';

typedef DecoderFunction<T> = FutureOr<T> Function(dynamic value);
typedef EncoderFunction<T> = FutureOr<dynamic> Function(T value);
typedef AuthorizationBuilder = FutureOr<Authorization?> Function();
typedef ExceptionHandler<T> = T Function(Exception e, StackTrace stackTrace);
typedef ExceptionInterceptor = Future<bool> Function(Object error, StackTrace stack, {required int attempts});

abstract class RestClient {
  static final _log = Logger("rest_client");

  static int _lineNumber = 0;
  static String get _nextLineName {
    _lineNumber++;
    if (_lineNumber > 9999) {
      _lineNumber = 0;
    }
    return "$_lineNumber".padLeft(4, "0");
  }

  late final String name = _nextLineName;

  Uri? _uri;
  Uri get uri => _uri!;

  void init(Uri uri) {
    _uri = uri;
  }

  // MARK: Decoder

  DecoderFunction? _decoder;
  RestClient decode({required DecoderFunction withDecoder}) {
    _decoder = withDecoder;
    return this;
  }

  // MARK: Encoder

  EncoderFunction? _encoder;
  RestClient encode({required EncoderFunction withEncoder}) {
    _encoder = withEncoder;
    return this;
  }

  // MARK: Headers

  final Map<String, dynamic> _headers = {};
  RestClient addHeader({required String name, required String value}) {
    _headers[name] = value;
    return this;
  }

  // MARK: Authorization

  AuthorizationBuilder? _authorization;
  RestClient authorization(AuthorizationBuilder? authorization) {
    _authorization = authorization;
    return this;
  }

  // MARK: Error handling

  ExceptionHandler? _exceptionHandler;
  RestClient onError(ExceptionHandler? handler) {
    _exceptionHandler = handler;
    return this;
  }

  // MARK: Exception interceptor

  ExceptionInterceptor? _exceptionInterceptor;
  RestClient errorInterceptor(ExceptionInterceptor? interceptor) {
    _exceptionInterceptor = interceptor;
    return this;
  }

  @protected
  ExceptionInterceptor? getErrorInterceptor() => _exceptionInterceptor ?? Rest.config.rest.errorInterceptor;

  // MARK: Stub

  FutureOr? _stub;
  RestClient stub<T>(FutureOr<T> stub) {
    _stub = stub;
    return this;
  }

  // MARK: HTTP Methods

  CancelableOperation<T> post<T>([dynamic data]);
  CancelableOperation<T> patch<T>([dynamic data]);
  CancelableOperation<T> get<T>() ;
  CancelableOperation<T> delete<T>([dynamic data]);

  // MARK: HTTP methods to implement

  @protected
  CancelableOperation<T> doPost<T>([dynamic data]);

  @protected
  CancelableOperation<T> doPatch<T>([dynamic data]);

  @protected
  CancelableOperation<T> doGet<T>();

  @protected
  CancelableOperation<T> doDelete<T>([dynamic data]);

  @protected
  CancelableOperation<T> doStub<T>(FutureOr stub, {required String method}) {
    _log.info("$name *STUB* ${method.toUpperCase()} ${uri.toString()} $stub");
    return CancelableOperation.fromFuture(Future(() async {
      return _decoder != null ? _decoder!(await _stub) : await _stub;
    }));
  }

}

mixin RestClientHelper on RestClient {

  Future<Authorization?> formAuthorization() async {
    final builder = _authorization ?? Rest.config.auth?.builder;
    if (builder == null) {
      return null;
    }
    return await builder();
  }

  Future<Map<String, dynamic>?> formHeaders() async {
    final headers = {..._headers};

    final authorization = await formAuthorization();
    if (authorization != null) {
      headers[authorization.name] = authorization.data;
    }

    return headers.isEmpty ? null : headers;
  }

  FutureOr<dynamic> encodeIfNeeded<T>(T value) {
    return _encoder != null ? _encoder!(value) : value;
  }

  FutureOr<T> decodeIfNeeded<T>(dynamic value) {
    return _decoder != null ? _decoder!(value) : value;
  }

  T handleException<T>(Exception error, StackTrace stackTrace) {
    if (_exceptionHandler == null) {
      throw error;
    }
    return _exceptionHandler!(error, stackTrace);
  }

  @override
  CancelableOperation<T> post<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "POST") : _request(() => doPost(data));
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> patch<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "PATCH") : _request(() => doPatch(data));
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> get<T>() {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "GET") : _request(() => doGet());
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> delete<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "DELETE") : _request(() => doDelete(data));
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  CancelableOperation<T> _request<T>(CancelableOperation<T> Function() generator) {
    final interceptor = getErrorInterceptor();
    if (interceptor == null) {
      return generator();
    }

    // based on https://github.com/dart-lang/async/issues/210
    // TODO: refactor to thenOperation() when available

    late CancelableOperation<T> operation;

    final completer = CancelableCompleter<T>(
        onCancel: () {
          operation.cancel();
        }
    );

    _retry(() => operation = generator(), completer, interceptor);

    return completer.operation;
  }

  _retry<T>(
    CancelableOperation<T> Function() generator,
    CancelableCompleter<T> completer,
    ExceptionInterceptor shouldRetry) async
  {
    var attempts = 0;
    for(;;) {
      try {
        final current = generator();
        var result = await current.valueOrCancellation();
        if (completer.isCanceled) {
          return;
        }
        if (current.isCompleted && !current.isCanceled) {
          completer.complete(result);
        } else {
          completer.operation.cancel();
        }
        return;
      } on Object catch (error, stack) {
        if (await shouldRetry(error, stack, attempts: attempts)) {
          attempts++;
          continue;
        }
        if (completer.isCanceled) {
          return;
        }
        completer.completeError(error, stack);
        return;
      }

    }

  }


  // CancelableOperation<T> _delete<T>([dynamic data]) {
  //   late CancelableOperation<T> operation;
  //   return doDelete(data).then((value) => value,
  //       onError: (error, stack) {
  //         operation = _delete(data);
  //         return operation.value;
  //       },
  //       onCancel: () {
  //         operation.cancel()
  //       });
  // }

}

extension on CancelableOperation {

  // CancelableOperation<R> retry<R>(Object? error, StackTrace? stack, CancelableOperation<R> Function() generator) {
  //
  //   final completer = CancelableCompleter(onCancel: () {
  //
  //   })
  //
  // }

  CancelableOperation<R> onEnd<R>(FutureOr<R> Function() listener) {
    return then((_) => listener(),
      onError: (_, __) => listener(),
      onCancel: () => listener(),
    );
  }

}

