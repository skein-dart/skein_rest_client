import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:skein_rest_client/skein_rest_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'skein_rest_client_test.mocks.dart';

@GenerateMocks([RestClient])
void main() {

  final api = "https://example.com/api";
  final client = MockRestClient();

  Rest.config = Config(
    rest: RestConfig(builder: () => client, api: api),
    auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
  );

  group("rest() function", () {
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

}
