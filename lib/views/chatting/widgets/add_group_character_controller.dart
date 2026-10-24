import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../../repository/character_dao.dart';
import '../../../repository/group_dao.dart';

/// Data-access boundary for the "add character to group" dialog.
///
/// Fronts the character / group DAOs so the dialog no longer reaches into the
/// global service locator for server interaction.
class AddGroupCharacterController extends ChangeNotifier {
  AddGroupCharacterController({CharacterDao? characterDao, GroupDao? groupDao})
      : _characterDao = characterDao ?? GetIt.instance<CharacterDao>(),
        _groupDao = groupDao ?? GetIt.instance<GroupDao>();

  final CharacterDao _characterDao;
  final GroupDao _groupDao;

  /// Search characters to add to the group.
  Future<ListCharacterResponse?> listCharacter(ListCharacterRequest request) =>
      _characterDao.listCharacter(request);

  /// Add the chosen character to the group.
  Future<AddCharacterResponse?> addCharacter(AddCharacterRequest request) =>
      _groupDao.addCharacter(request);
}
