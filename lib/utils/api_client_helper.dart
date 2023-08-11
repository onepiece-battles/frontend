import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/secure_storage.dart';
import 'package:openapi/api.dart';

class ApiClientHelper {
    final log = Logger('ApiClientHelper');
    ApiClient getApiClient() {
    var token = SecureStorage.readAccessToken();
    HttpBearerAuth httpBearerAuth = HttpBearerAuth();
    token.then((value) => httpBearerAuth.accessToken=value??"");
    var accessToken = httpBearerAuth.accessToken;
    log.info("the most recent access token is $accessToken");
    return ApiClient(authentication: httpBearerAuth);
  }
}
