import 'package:flutter/widgets.dart';
import 'package:openapi/api.dart';

class AuthenticationHolder {
  static HttpBearerAuth auth = HttpBearerAuth();

  static void setAuthentication (String token) {
    var bearAuth = HttpBearerAuth();
    bearAuth.accessToken = token;
    auth = bearAuth;
    debugPrint("current set token is $auth$token");
  }

  static HttpBearerAuth getAuthentication () {
    debugPrint("current auth $auth");
    return auth;
  }
}