import 'package:openapi/api.dart';

class GroupDao{
  GroupApi groupApi = GroupApi();
  GroupDao.empty();
  GroupDao(ApiClient apiClient) {
    groupApi = GroupApi(apiClient);
  }

  Future<CreateGroupResponse?> createGroup(CreateGroupRequest request) async {
    return await groupApi.createGroup(request);
  }

  Future<GroupFullView?> getGroupFullView(GetGroupRequest request) async {
    return await groupApi.getGroupFullView(request);
  }

  Future<ListGroupResponse?> listGroups(ListGroupRequest request) async {
    return await groupApi.listGroups(request);
  }

  Future<UpdateGroupResponse?> updateGroups(Group group) async {
    return await groupApi.updateGroup(group);
  }
}