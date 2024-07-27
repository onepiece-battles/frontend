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

  Future<LogoutResponse?> logout(LogoutRequest logoutRequest) async {
    return await userApi.logout(logoutRequest);
  }

  Future<User?> get(GetUserRequest getUserRequest) async {
    return await userApi.getUser(getUserRequest: getUserRequest);
  }

  Future<UpdateUserResponse?> updateUser(UpdateUserRequest request) async {
    return await userApi.updateUser(updateUserRequest: request);
  }

  Future<VerifyByEmailCodeResponse?> verifyEmail(
      VerifyByEmailCodeRequest request) async {
    return await userApi.verifyByEmailCode(request);
  }

  Future<ListUsersResponse?> listUser(ListUsersRequest request) async {
    return await userApi.listUsers(request);
  }

  Future<UpdateLoginRoleResponse?> updateLoginRole(
      UpdateLoginRoleRequest request) async {
    return await userApi.updateRole(request);
  }

  Future<UpdatePasswordResponse?> updatePassword(
      UpdatePasswordRequest request) async {
    return await userApi.updatePassword(request);
  }
}
