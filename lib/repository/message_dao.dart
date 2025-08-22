import 'package:openapi/api.dart';


class MessageDao {
  MessageApi messageApi = MessageApi();

  MessageDao(ApiClient apiClient) {
    messageApi = MessageApi(apiClient);
  }

  MessageDao.empty();

  Future<SendMessageResponse?> sendMessage(SendMessageRequest request) async {
    return await messageApi.sendMessage(request);
  }

  Future<RetractMessageResponse?> retractMessage(RetractMessageRequest request) async {
    return await messageApi.retractMessage(request);
  }

  Future<ListMessageResponse?> listMessage(ListMessageRequest request) async {
    return await messageApi.listMessage(request);
  }

  Future<JumpToMessageResponse?> jumpToMessage(JumpToMessageRequest request) async {
    return await messageApi.jumpToMessage(request);
  }
}