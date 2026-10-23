import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/issue_dao.dart';

/// Data-access boundary for the issue list screen.
///
/// Fronts [IssueDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class IssueListController extends ChangeNotifier {
  IssueListController({IssueDao? issueDao})
      : _issueDao = issueDao ?? GetIt.instance<IssueDao>();

  final IssueDao _issueDao;

  /// List issues matching the given filter / paging / sort request.
  Future<ListIssueResponse?> listIssue(ListIssueRequest request) =>
      _issueDao.listIssue(request);
}
