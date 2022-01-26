import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:skein_rest_client/skein_rest_client.dart';

part 'rest_client_registry.dart';

typedef DecoderFunction<T> = FutureOr<T> Function(dynamic value);
typedef EncoderFunction<T> = FutureOr<dynamic> Function(T value);
typedef AuthorizationBuilder = FutureOr<Authorization?> Function();

abstract class RestClient {
  static late final _log = Logger("rest_client");

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
    final headers = <String, dynamic> {};

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

  @override
  CancelableOperation<T> post<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "POST") : doPost(data);
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> patch<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "PATCH") : doPatch(data);
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> get<T>() {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "GET") : doGet();
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

  @override
  CancelableOperation<T> delete<T>([dynamic data]) {
    final CancelableOperation<T> operation = _stub != null ? doStub(_stub, method: "DELETE") : doDelete(data);
    operation.onEnd(() => RestClientRegistry.reuse(this));
    return operation;
  }

}

extension on CancelableOperation {

  CancelableOperation<R> onEnd<R>(FutureOr<R> Function() listener) {
    return then((_) => listener(),
      onError: (_, __) => listener(),
      onCancel: () => listener(),
    );
  }

}