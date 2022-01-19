// MARK: - Authorization

abstract class Authorization {
  final String name = "Authorization";
  String get data;
}

class BearerAuthorization with Authorization {

  @override
  final String data;

  BearerAuthorization({required String token}) : data = "Bearer $token";

}