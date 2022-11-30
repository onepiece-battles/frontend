import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

class AccountRepository {
  final AccountApi accountApi = Openapi().getAccountApi();

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    Response<RegisterResponse> registerResponse =
        await accountApi.register(registerRequest: registerRequest);
    return registerResponse.data!;
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    Response<LoginResponse> loginResponse =
        await accountApi.login(loginRequest: loginRequest);
    return loginResponse.data!;
  }
}
