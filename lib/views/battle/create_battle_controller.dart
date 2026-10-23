import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/battle_dao.dart';
import '../../repository/character_dao.dart';

/// Data-access boundary for the create-battle screen.
///
/// Fronts the character / battle DAOs so the view no longer reaches into the
/// global service locator for server interaction, giving the feature a single,
/// mockable seam.
class CreateBattleController extends ChangeNotifier {
  CreateBattleController({CharacterDao? characterDao, BattleDao? battleDao})
      : _characterDao = characterDao ?? GetIt.instance<CharacterDao>(),
        _battleDao = battleDao ?? GetIt.instance<BattleDao>();

  final CharacterDao _characterDao;
  final BattleDao _battleDao;

  /// Search characters for the combatant pickers.
  Future<ListCharacterResponse?> listCharacter(ListCharacterRequest request) =>
      _characterDao.listCharacter(request);

  /// Create the battle from the two chosen combatants.
  Future<CreateBattleResponse?> createBattle(CreateBattleRequest request) =>
      _battleDao.createBattle(request);
}
