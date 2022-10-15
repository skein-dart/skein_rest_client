part of 'rest_client.dart';

class RestClientRegistry {

  static final List<RestClient> _registry = [];

  static RestClient get() {
    if (_registry.isNotEmpty) {
      return _registry.removeAt(0);
    }
    return Rest.config.rest.builder();
  }

  static void clear() {
    _registry.clear();
  }

  static void reuse(RestClient client) {
    if (_registry.length > 2) {
      return;
    }
    client._uri = null;
    client._encoder = null;
    client._decoder = null;
    client._headers.clear();
    client._authorization = null;
    client._exceptionHandler = null;
    client._exceptionInterceptor = null;
    client._stub = null;
    _registry.add(client);
  }

}