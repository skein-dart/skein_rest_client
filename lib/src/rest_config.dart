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

  const RestConfig({
    required this.builder,
    this.api,
    this.errorInterceptor,
  });

}

class AuthConfig {

  final AuthorizationBuilder builder;

  const AuthConfig({required this.builder});

}
