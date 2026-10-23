import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/issue_dao.dart';

/// Data-access boundary for the issue detail screen.
///
/// Fronts [IssueDao] so the view no longer reaches into the global service
/// locator for server interaction, giving the feature a single, mockable seam.
class IssueDetailController extends ChangeNotifier {
  IssueDetailController({IssueDao? issueDao})
      : _issueDao = issueDao ?? GetIt.instance<IssueDao>();

  final IssueDao _issueDao;

  /// Load the full view of an issue.
  Future<IssueFullView?> getIssueFullView(GetIssueFullViewRequest request) =>
      _issueDao.getIssueFullView(request);

  /// Apply a batch of status / field changes to issues.
  Future<void> batchUpdateIssue(BatchUpdateIssueRequest request) =>
      _issueDao.batchUpdateIssue(request);
}
