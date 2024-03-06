import 'package:openapi/api.dart';

class IssueDao {
  IssueApi issueApi = IssueApi();
  IssueDao(ApiClient apiClient) {
    issueApi = IssueApi(apiClient);
  }
  IssueDao.empty();

  Future<CreateIssueResponse?> createIssue(CreateIssueRequest request) async {
    return await issueApi.createIssue(request);
  }

  Future<ListIssueResponse?> listIssue(ListIssueRequest request) async {
    return await issueApi.listIssue(request);
  }

  Future<void> batchUpdateIssue(BatchUpdateIssueRequest request) async {
    return await issueApi.batchUpdateIssue(request);
  }

  Future<IssueFullView?> getIssueFullView(GetIssueFullViewRequest request) async {
    return await issueApi.getIssueFullView(request);
  }
}