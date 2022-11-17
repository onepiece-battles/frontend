import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AccountApi
void main() {
  final instance = Openapi().getAccountApi();

  group(AccountApi, () {
    //Future<LoginResponse> login(LoginRequest loginRequest) async
    test('test login', () async {
      // TODO
    });

    //Future<LogoutResponse> logout(LogoutRequest logoutRequest) async
    test('test logout', () async {
      // TODO
    });

    //Future<RegisterResponse> register(RegisterRequest registerRequest) async
    test('test register', () async {
      // TODO
    });

  });
}
