import 'package:async/async.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:skein_rest_client/skein_rest_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'skein_rest_client_test.mocks.dart';

@GenerateMocks([RestClient, CancelableOperation])
void main() {

  final api = "https://example.com/api";

  group("rest() function", () {
    final client = MockRestClient();

    setUp(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => client, api: api),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });

    tearDown(() {
      reset(client);
    });

    test("Parse URI based on the path argument", () {
      rest(path: "/test-endpoint");
      verify(client.init(argThat(equals(Uri.parse("$api/test-endpoint"))))).called(1);
    });

    test("Parse URI based on the url argument", () {
      rest(url: "https://url-api.com/api/test-endpoint");
      verify(client.init(argThat(equals(Uri.parse("https://url-api.com/api/test-endpoint"))))).called(1);
    });

    test("Parse URI based on the uri argument", () {
      rest(uri: Uri.parse("https://uri-api.com/api/test-endpoint"));
      verify(client.init(argThat(equals(Uri.parse("https://uri-api.com/api/test-endpoint"))))).called(1);
    });

    test("No passed params throws ArgumentError error", () {
      ArgumentError? argumentError;
      try {
        rest();
      } on ArgumentError catch (error, _) {
        argumentError = error;
      }
      expect(argumentError, isNotNull);
    });

    test("Parse URI based on the path argument including base part for API", () {
      Rest.config = Config(
        rest: RestConfig(builder: () => client),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
      rest(path: "https://path-api.com/api/test-endpoint");
      verify(client.init(argThat(equals(Uri.parse("https://path-api.com/api/test-endpoint"))))).called(1);
    });

  });

  group("Config", () {
    final client = MockRestClient();
    setUpAll(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => client, api: api),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });

    test("RestConfig correctly configured", () {
      expect(Rest.config.rest.builder(), equals(client));
      expect(Rest.config.rest.api, api);
    });

    test("AuthConfig correctly configured", () async {
      final authorization = await Rest.config.auth?.builder();
      expect(authorization, TypeMatcher<BearerAuthorization>());
      expect(authorization?.data, "Bearer test_token");
    });

  });

  group("RestClient", () {
    final client = _MockRestClient();

    setUp(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => client, api: api),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });

    tearDown(() {
      reset(client);
    });

    test("Set decoder", () {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      final decoder = _MockDecoder();
      client.decode(withDecoder: decoder);
      client.decodeIfNeeded("test");
      verify(decoder("test")).called(1);
    });

    test("Set encoder", () {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      final encoder = _MockEncoder();
      client.encode(withEncoder: encoder);
      client.encodeIfNeeded("test");
      verify(encoder("test")).called(1);
    });

    test("Add header", () async {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      client.addHeader(name: "test_header", value: "test_header_value");
      final headers = await client.formHeaders();
      expect(headers, containsPair("test_header", "test_header_value"));
    });

    test("Set Authorization header", () async {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      client.authorization(() => BearerAuthorization(token: "custom_test_token"));
      final authorization = await client.formAuthorization();
      expect(authorization?.data, "Bearer custom_test_token");
    });

    test("Set exception handler", () {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      final handler = _MockExceptionHandler();
      client.onError(handler);
      final exception = Exception("test_exception");
      final stackTrace = StackTrace.empty;
      client.handleException(exception, stackTrace);
      verify(handler(exception, stackTrace)).called(1);
    });

    test("Rethrow exception if no handler specified", () {
      final client = _StubRestClient(CancelableOperation.fromFuture(Future.value("")));
      final exception = Exception("test_exception");
      final stackTrace = StackTrace.empty;
      expect(() => client.handleException(exception, stackTrace), throwsA(exception));
    });
  });

  group("RestClient HTTP stubbing", () {
    final realData = {"username": "real_user", "password": "real_pass"};
    final fakeData = {"username": "fake_user", "password": "fake_pass"};
    final real = CancelableOperation.fromFuture(Future.value(realData));
    var client = _StubRestClient(real);

    setUpAll(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => client, api: api),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });


    tearDown(() {

    });

    test("stub().post()", () async {
      expect(await rest(path: "/test-endpoint").post().value, realData);
      expect(await rest(path: "/test-endpoint").stub(fakeData).post().value, fakeData);
    });

    test("stub().get()", () async {
      expect(await rest(path: "/test-endpoint").get().value, realData);
      expect(await rest(path: "/test-endpoint").stub(fakeData).get().value, fakeData);
    });

    test("stub().patch()", () async {
      expect(await rest(path: "/test-endpoint").patch().value, realData);
      expect(await rest(path: "/test-endpoint").stub(fakeData).patch().value, fakeData);
    });

    test("stub().delete()", () async {
      expect(await rest(path: "/test-endpoint").delete().value, realData);
      expect(await rest(path: "/test-endpoint").stub(fakeData).delete().value, fakeData);
    });

  });

  group("RestClient HTTP call cancellation", () {
    final client = _MockRestClient();

    setUp(() {
      Rest.config = Config(
          rest: RestConfig(builder: () => client, api: api),
          auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });

    tearDown(() {
      reset(client);
    });

    test("Cancel get()", () {
      final operation = MockCancelableOperation();
      final client = _StubRestClient(operation);
      // when(client.doGet()).thenReturn(expected)
    });
  });

}

abstract class _Decoder<T> {
  T call(dynamic value);
}
class _MockDecoder<T> extends Mock implements _Decoder<T> {}

abstract class _Encoder<T> {
  dynamic call(T value);
}
class _MockEncoder<T> extends Mock implements _Encoder<T> {}

abstract class _ExceptionHandler<T> {
  T call(Exception error, StackTrace stack);
}
class _MockExceptionHandler<T> extends Mock implements _ExceptionHandler<T> {}

class _MockRestClient extends MockRestClient with RestClientHelper {}

class _StubRestClient extends RestClient with RestClientHelper {

  final CancelableOperation operation;

  _StubRestClient(this.operation);

  @override
  CancelableOperation<T> doDelete<T>([data]) {
    return operation as CancelableOperation<T>;
  }

  @override
  CancelableOperation<T> doGet<T>([data]) {
    return operation as CancelableOperation<T>;
  }

  @override
  CancelableOperation<T> doPatch<T>([data]) {
    return operation as CancelableOperation<T>;
  }

  @override
  CancelableOperation<T> doPost<T>([data]) {
    return operation as CancelableOperation<T>;
  }

}
