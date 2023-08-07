import 'package:one_piece_battles_flutter/secure_storage.dart';
import 'package:openapi/api.dart';

class ApiClientHelper {
  static ApiClient getApiClient() {
    var token = SecureStorage.readAccessToken();
    HttpBearerAuth httpBearerAuth = HttpBearerAuth();
    token.then((value) => httpBearerAuth.accessToken=value??"");
    return ApiClient(authentication: httpBearerAuth);
  }
}
