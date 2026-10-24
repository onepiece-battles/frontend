import 'package:flutter/foundation.dart';
import 'package:openapi/api.dart';

/// Mutable, observable snapshot of a battle's execution state (status, report
/// stage, winner and score deltas). The detail view polls the backend and
/// pushes updates into this notifier; widgets listen for rebuilds.
class BattleExecutionData extends ChangeNotifier {
  BattleStatus _battleStatus;
  BattleReportStage _battleReportStage;
  String? _reportFileId;
  String? _winnerId;
  int? _winnerScoreChange;
  int? _loserScoreChange;

  int? _starterScoreBefore;
  int? _starterScoreAfter;
  int? _receiverScoreBefore;
  int? _receiverScoreAfter;

  BattleExecutionData(
      this._battleStatus,
      this._battleReportStage,
      this._reportFileId,
      this._winnerId,
      this._winnerScoreChange,
      this._loserScoreChange,
      this._starterScoreBefore,
      this._starterScoreAfter,
      this._receiverScoreBefore,
      this._receiverScoreAfter);

  BattleStatus get battleStatus => _battleStatus;

  BattleReportStage get battleReportStage => _battleReportStage;

  String? get reportFileId => _reportFileId;

  String? get winnerId => _winnerId;

  int? get winnerScoreChange => _winnerScoreChange;

  int? get loserScoreChange => _loserScoreChange;

  int? get receiverScoreBefore => _receiverScoreBefore;

  int? get receiverScoreAfter => _receiverScoreAfter;

  int? get starterScoreBefore => _starterScoreBefore;

  int? get starterScoreAfter => _starterScoreAfter;

  set battleStatus(BattleStatus battleStatus) {
    if (_battleStatus != battleStatus) {
      _battleStatus = battleStatus;
      notifyListeners();
    }
  }

  set battleReportStage(BattleReportStage battleReportStage) {
    if (_battleReportStage != battleReportStage) {
      _battleReportStage = battleReportStage;
      notifyListeners();
    }
  }

  set reportFileId(String? reportFileId) {
    if (_reportFileId != reportFileId) {
      _reportFileId = reportFileId;
      notifyListeners();
    }
  }

  set winnerId(String? winnerId) {
    if (_winnerId != winnerId) {
      _winnerId = winnerId;
      notifyListeners();
    }
  }

  set winnerScoreChange(int? winnerScoreChange) {
    if (_winnerScoreChange != winnerScoreChange) {
      _winnerScoreChange = winnerScoreChange;
      notifyListeners();
    }
  }

  set loserScoreChange(int? loserScoreChange) {
    if (_loserScoreChange != loserScoreChange) {
      _loserScoreChange = loserScoreChange;
      notifyListeners();
    }
  }

  set starterScoreBefore(int? starterScoreBefore) {
    if (_starterScoreBefore != starterScoreBefore) {
      _starterScoreBefore = starterScoreBefore;
      notifyListeners();
    }
  }

  set starterScoreAfter(int? starterScoreAfter) {
    if (_starterScoreAfter != starterScoreAfter) {
      _starterScoreAfter = starterScoreAfter;
      notifyListeners();
    }
  }

  set receiverScoreBefore(int? receiverScoreBefore) {
    if (_receiverScoreBefore != receiverScoreBefore) {
      _receiverScoreBefore = receiverScoreBefore;
      notifyListeners();
    }
  }

  set receiverScoreAfter(int? receiverScoreAfter) {
    if (_receiverScoreAfter != receiverScoreAfter) {
      _receiverScoreAfter = receiverScoreAfter;
      notifyListeners();
    }
  }
}
