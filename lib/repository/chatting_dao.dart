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

  Future<Chat?> joinChat(JoinChatRequest request) async {
    return await chattingApi.joinChat(request);
  }
}