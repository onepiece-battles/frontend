import 'package:one_piece_battles_flutter/utils/api_client_helper.dart';
import 'package:openapi/api.dart';

class UserDao {
  UserApi userApi = UserApi(ApiClientHelper.getApiClient());
  Future<RegisterResponse?> register(RegisterRequest registerRequest) async {
    return await userApi.register(registerRequest);
  }

  Future<LoginResponse?> login(LoginRequest loginRequest) async {
    return await userApi.login(loginRequest);
  }
}
