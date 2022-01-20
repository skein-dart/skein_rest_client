import 'package:async/async.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:skein_rest_client/skein_rest_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'skein_rest_client_test.mocks.dart';

@GenerateMocks([RestClient])
void main() {

  final api = "https://example.com/api";

  group("rest() function", () {
    final client = MockRestClient();

    setUpAll(() {
      Rest.config = Config(
        rest: RestConfig(builder: () => client, api: api),
        auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
      );
    });

    tearDown(() {
      reset(client);
    });

    test("Passes correct URI based on the path argument", () {
      rest(path: "/test-endpoint");
      verify(client.init(argThat(equals(Uri.parse("$api/test-endpoint"))))).called(1);
    });

    test("Passes correct URL based on the url argument", () {
      rest(url: "https://url-api.com/api/test-endpoint");
      verify(client.init(argThat(equals(Uri.parse("https://url-api.com/api/test-endpoint"))))).called(1);
    });

    test("Passes correct URI based on the url argument", () {
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
    final realData = {"username": "real_user", "password": "real_pass"};
    final fakeData = {"username": "fake_user", "password": "fake_pass"};
    var client = TestRestClient(realData);

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

}

class TestRestClient extends RestClient with RestClientHelper {

  final dynamic returnValue;

  TestRestClient(this.returnValue);

  @override
  CancelableOperation<T> doDelete<T>([data]) {
    return CancelableOperation.fromFuture(Future.value(returnValue));
  }

  @override
  CancelableOperation<T> doGet<T>([data]) {
    return CancelableOperation.fromFuture(Future.value(returnValue));
  }

  @override
  CancelableOperation<T> doPatch<T>([data]) {
    return CancelableOperation.fromFuture(Future.value(returnValue));
  }

  @override
  CancelableOperation<T> doPost<T>([data]) {
    return CancelableOperation.fromFuture(Future.value(returnValue));
  }

}
