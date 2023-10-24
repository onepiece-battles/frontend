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

  Future<User?> get(GetUserRequest getUserRequest) async {
    return await userApi.getUser(getUserRequest: getUserRequest);
  }

  Future<UpdateUserResponse?> updateUser(UpdateUserRequest request) async {
    return await userApi.updateUser(updateUserRequest: request);
  }

  Future<VerifyEmailResponse?> verifyEmail(VerifyEmailRequest request) async {
    return await userApi.verifyUserEmail(verifyEmailRequest: request);
  }
}
