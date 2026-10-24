import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/battle_dao.dart';

/// Data-access boundary for the battle list screen.
///
/// Fronts [BattleDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class BattleListController extends ChangeNotifier {
  BattleListController({BattleDao? battleDao})
      : _battleDao = battleDao ?? GetIt.instance<BattleDao>();

  final BattleDao _battleDao;

  /// List battles matching the given filter / paging / sort request.
  Future<ListBattleResponse?> listBattles(ListBattleRequest request) =>
      _battleDao.listBattles(request);
}
