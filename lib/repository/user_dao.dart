import 'package:openapi/api.dart';

class UserDao {
  UserApi userApi = UserApi();
  UserDao.empty();

  UserDao(ApiClient apiClient) {
    userApi = UserApi(apiClient);
  }

  Future<RegisterResponse?> register(RegisterRequest registerRequest) async {
    return await userApi.register(registerRequest);
  }

  Future<LoginResponse?> login(LoginRequest loginRequest) async {
    return await userApi.login(loginRequest);
  }
}
