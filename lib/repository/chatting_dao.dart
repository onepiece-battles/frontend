import 'package:openapi/api.dart';


class ChattingDao {
  ChattingApi chattingApi = ChattingApi();

  ChattingDao(ApiClient apiClient) {
    chattingApi = ChattingApi(apiClient);
  }

  ChattingDao.empty();

  Future<Chat?> createChat(CreateChatRequest request) async {
    return await  chattingApi.createChat(request);
  }

  Future<ListChatResponse?> listChat(ListChatRequest request) async {
    return await chattingApi.listChat(request);
  }

  Future<SendMessageResponse?> sendMessage(SendMessageRequest request) async {
    return await chattingApi.sendMessage(request);
  }

  Future<RetractMessageResponse?> retractMessage(RetractMessageRequest request) async {
    return await chattingApi.retractMessage(request);
  }

  Future<Chat?> joinChat(JoinChatRequest request) async {
    return await chattingApi.joinChat(request);
  }

  Future<ListMessageResponse?> listMessage(ListMessageRequest request) async {
    return await chattingApi.listMessage(request);
  }
}