import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/battle_dao.dart';
import '../../repository/file_dao.dart';

/// Data-access boundary for the battle detail screen.
///
/// Fronts the battle / file DAOs so the view no longer reaches into the global
/// service locator for server interaction, giving the feature a single,
/// mockable seam.
class BattleDetailController extends ChangeNotifier {
  BattleDetailController({BattleDao? battleDao, FileDao? fileDao})
      : _battleDao = battleDao ?? GetIt.instance<BattleDao>(),
        _fileDao = fileDao ?? GetIt.instance<FileDao>();

  final BattleDao _battleDao;
  final FileDao _fileDao;

  /// Load the full view of a battle.
  Future<BattleFullView?> getBattleFullView(GetBattleFullViewRequest request) =>
      _battleDao.getBattleFullView(request);

  /// Load the execution (scores / winner / status) of a battle.
  Future<BattleExecution?> getBattleExecution(
          GetBattleExecutionRequest request) =>
      _battleDao.getBattleExecution(request);

  /// Create a (re-match) battle.
  Future<CreateBattleResponse?> createBattle(CreateBattleRequest request) =>
      _battleDao.createBattle(request);

  /// Start a battle execution.
  Future<StartBattleResponse?> startBattle(StartBattleRequest request) =>
      _battleDao.startBattle(request);

  /// Download the battle replay / report file.
  Future<DownloadFileResponse?> downloadFile(DownloadFileRequest request) =>
      _fileDao.downloadFile(request);
}
