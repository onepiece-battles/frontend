import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/group_dao.dart';

/// Data-access boundary for the group list screen.
///
/// Fronts [GroupDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class GroupListController extends ChangeNotifier {
  GroupListController({GroupDao? groupDao})
      : _groupDao = groupDao ?? GetIt.instance<GroupDao>();

  final GroupDao _groupDao;

  /// List groups matching the given filter / paging / sort request.
  Future<ListGroupResponse?> listGroups(ListGroupRequest request) =>
      _groupDao.listGroups(request);
}
