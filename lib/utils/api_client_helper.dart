import 'package:one_piece_battles_flutter/constants/common_constants.dart';
import 'package:one_piece_battles_flutter/secure_storage.dart';
import 'package:openapi/api.dart';

class ApiClientHelper {
  static ApiClient getApiClient() {
    String token = SecureStorage.readAccessToken();
    HttpBearerAuth httpBearerAuth = HttpBearerAuth();
    httpBearerAuth.accessToken(token);
    return ApiClient(authentication: httpBearerAuth);
  }
}
