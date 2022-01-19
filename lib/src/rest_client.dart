import 'dart:async';

import 'package:async/async.dart';
import 'package:skein_rest_client/skein_rest_client.dart';

typedef DecoderFunction<T> = FutureOr<T> Function(dynamic value);
typedef EncoderFunction<T> = FutureOr<dynamic> Function(T value);
typedef AuthorizationBuilder = FutureOr<Authorization?> Function();

abstract class RestClient {

  late Uri uri;

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

  void init(Uri uri) => this.uri = uri;

  // MARK: HTTP Methods

  CancelableOperation<T> post<T>([dynamic data]);

  CancelableOperation<T> patch<T>([dynamic data]);

  CancelableOperation<T> get<T>();

  CancelableOperation<T> delete<T>([dynamic data]);

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
    if (_encoder == null) {
      return value;
    }
    return _encoder!(value);
  }

  FutureOr<T> decodeIfNeeded<T>(dynamic value) {
    final aDecoder = _decoder as DecoderFunction<T>?;
    if (aDecoder == null) {
      return value;
    }
    return aDecoder(value);
  }

}