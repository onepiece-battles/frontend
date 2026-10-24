import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/group_dao.dart';
import '../../repository/image_dao.dart';

/// Data-access boundary for the create-group screen.
///
/// Fronts the group / image DAOs so the view no longer reaches into the global
/// service locator for server interaction, giving the feature a single,
/// mockable seam.
class CreateGroupController extends ChangeNotifier {
  CreateGroupController({GroupDao? groupDao, ImageDao? imageDao})
      : _groupDao = groupDao ?? GetIt.instance<GroupDao>(),
        _imageDao = imageDao ?? GetIt.instance<ImageDao>();

  final GroupDao _groupDao;
  final ImageDao _imageDao;

  /// Create a new group.
  Future<CreateGroupResponse?> createGroup(CreateGroupRequest request) =>
      _groupDao.createGroup(request);

  /// Upload the new group's avatar image.
  Future<UploadImageResponse?> addImage(UploadImageRequest request) =>
      _imageDao.addImage(request);
}
