import 'package:skein_rest_client/skein_rest_client.dart';

RestClient rest({Uri? uri, String? url, String? path}) {
  final client = Rest.config.rest.builder();
  client.init(_uriFrom(uri: uri, url: url, path: path));
  return client;
}

Uri _uriFrom({Uri? uri, String? url, String? path}) {
  if (uri != null) {
    return uri;
  }
  if (url != null) {
    return Uri.parse(url);
  }
  if (path == null) {
    throw ArgumentError('One of the "uri", "url" or "path" parameter must be provided.');
  }
  if (Rest.config.rest.api != null) {
    return Uri.parse(Rest.config.rest.api! + path);
  }
  return Uri.parse(path);
}