import 'package:openapi/api.dart';

class EmailDao {
  EmailApi emailApi = EmailApi();
  EmailDao.empty();

  EmailDao(ApiClient apiClient) {
    emailApi = EmailApi(apiClient);
  }

  Future<VerifyEmailAddressResponse?> verifyEmailAddress(VerifyEmailAddressRequest request) async {
    return await emailApi.verifyEmailAddress(verifyEmailAddressRequest: request);
  }

  Future<PasswordRetrievalResponse?> sendRetrievalEmail(PasswordRetrievalRequest request) async {
    return await emailApi.sendRetrievalEmail(request);
  }
}