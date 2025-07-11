import 'package:openapi/api.dart';
class NotificationDao {
  NotificationApi notificationApi = NotificationApi();

  NotificationDao.empty();

  NotificationDao(ApiClient apiClient) {
    notificationApi = NotificationApi(apiClient);
  }

  Future<CloseNotificationResponse?> close(CloseNotificationRequest request) async {
    return notificationApi.close(closeNotificationRequest: request);
  }

  Future<CreateNotificationResponse?> create(CreateNotificationRequest request) async {
    return notificationApi.create(request);
  }
}