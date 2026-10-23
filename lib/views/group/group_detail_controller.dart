import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/character_dao.dart';
import '../../repository/group_dao.dart';
import '../../repository/image_dao.dart';

/// Data-access boundary for the group detail screen.
///
/// Fronts the group / image / character DAOs so the view no longer reaches into
/// the global service locator for server interaction, giving the feature a
/// single, mockable seam.
class GroupDetailController extends ChangeNotifier {
  GroupDetailController({
    GroupDao? groupDao,
    ImageDao? imageDao,
    CharacterDao? characterDao,
  })  : _groupDao = groupDao ?? GetIt.instance<GroupDao>(),
        _imageDao = imageDao ?? GetIt.instance<ImageDao>(),
        _characterDao = characterDao ?? GetIt.instance<CharacterDao>();

  final GroupDao _groupDao;
  final ImageDao _imageDao;
  final CharacterDao _characterDao;

  /// Load the full view of a group (with its members and sub-groups).
  Future<GroupFullView?> getGroupFullView(GetGroupRequest request) =>
      _groupDao.getGroupFullView(request);

  /// Persist group changes.
  Future<UpdateGroupResponse?> updateGroups(Group group) =>
      _groupDao.updateGroups(group);

  /// Lazily load the sub-groups of a group node in the member tree.
  Future<ListChildGroupsResponse?> listChildGroups(
          ListChildGroupsRequest request) =>
      _groupDao.listChildGroups(request);

  /// Lazily load the characters of a group node in the member tree.
  Future<ListChildCharactersResponse?> listChildCharacters(
          ListChildCharactersRequest request) =>
      _groupDao.listChildCharacters(request);

  /// Upload a new group avatar image.
  Future<UploadImageResponse?> addImage(UploadImageRequest request) =>
      _imageDao.addImage(request);

  /// Load a single character's full view (for the inline combat-stat panel).
  Future<CharacterFullView?> getCharacter(
          GetCharacterFullViewRequest request) =>
      _characterDao.getCharacter(request);
}
