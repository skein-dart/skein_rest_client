import 'package:async/src/cancelable_operation.dart';
import 'package:skein_rest_client/skein_rest_client.dart';
import 'package:skein_rest_client/src/rest_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main() {

  group("RestClientRegistry", () {

    setUpAll(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => _TestRestClient(Uri.parse("https://example.com/api"))),
      );
    });

    test("Cache RestClient instance", () {
      final client = _TestRestClient(Uri.parse("https://example.com/cache"));
      RestClientRegistry.reuse(client);
      expect(RestClientRegistry.get(), equals(client));
    });

    test("Cache only two RestClient instances", () {
      final client1 = _TestRestClient(Uri.parse("https://example.com/client1"));
      final client2 = _TestRestClient(Uri.parse("https://example.com/client2"));
      final client3 = _TestRestClient(Uri.parse("https://example.com/client3"));
      RestClientRegistry.reuse(client1);
      RestClientRegistry.reuse(client2);
      expect(RestClientRegistry.get(), equals(client1));
      expect(RestClientRegistry.get(), equals(client2));
      expect(RestClientRegistry.get(), isNot(equals(client3)));
    });

    test("Clear cache", () {
      final client = _TestRestClient(Uri.parse("https://example.com/cache"));
      RestClientRegistry.reuse(client);
      RestClientRegistry.clear();
      expect(RestClientRegistry.get(), isNot(equals(client)));
    });

  });

}

class _TestRestClient extends RestClient with RestClientHelper {

  _TestRestClient(Uri uri) {
    init(uri);
  }

  @override
  CancelableOperation<T> doDelete<T>([data]) {
    throw UnimplementedError();
  }

  @override
  CancelableOperation<T> doGet<T>() {
    throw UnimplementedError();
  }

  @override
  CancelableOperation<T> doPatch<T>([data]) {
    throw UnimplementedError();
  }

  @override
  CancelableOperation<T> doPost<T>([data]) {
    throw UnimplementedError();
  }

}