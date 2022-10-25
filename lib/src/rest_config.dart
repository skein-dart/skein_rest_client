import 'package:skein_rest_client/skein_rest_client.dart';

typedef RestClientBuilder = RestClient Function();

class Config {

  final RestConfig rest;

  final AuthConfig? auth;

  const Config({
    required this.rest,
    this.auth
  });

}

class RestConfig {

  final RestClientBuilder builder;

  final String? api;

  final ExceptionInterceptor? errorInterceptor;

  final ExceptionHandler? onError;

  const RestConfig({
    required this.builder,
    this.api,
    this.errorInterceptor,
    this.onError,
  });

}

class AuthConfig {

  final AuthorizationBuilder builder;

  const AuthConfig({required this.builder});

}
