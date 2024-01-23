import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:provider/provider.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;

class BattleDetailView extends StatefulWidget {
  final String battleId;
  const BattleDetailView({super.key, required this.battleId});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  Timer? _timer;
  late BattleFullView battle;
  late BattleExecutionData battleExecutionData;
  late Character starter;
  late Character receiver;

  Map<BattleStatus, int> statusOrderMap = {
    BattleStatus.CREATED: 1,
    BattleStatus.IN_PROGRESS: 2,
    BattleStatus.FINISHED: 3,
    BattleStatus.FAILED: 3
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  _loadData() {
    return getIt<BattleDao>()
        .getBattleFullView(GetBattleFullViewRequest(battleId: widget.battleId));
  }

  _getBattleExecution() {
    _timer?.cancel();
    GetBattleExecutionRequest request =
        GetBattleExecutionRequest(battleId: battle.id);
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      getIt<BattleDao>()
          .getBattleExecution(request)
          .then((value) => _updateBattleExecution(value!));
    });
  }

  void _updateData(BattleFullView battleFullView) {
    battle = battleFullView;
    battleExecutionData = BattleExecutionData(
        battle.battleExecution!.battleStatus!,
        battle.battleExecution!.battleReportStage!,
        battle.battleExecution!.reportFileId,
        battle.battleExecution!.winnerId);
    starter = battleFullView.starter!;
    receiver = battleFullView.receiver!;
  }

  void _updateBattleExecution(BattleExecution battleExecution) {
    battleExecutionData.battleStatus = battle.battleExecution!.battleStatus!;
    battleExecutionData.battleReportStage =
        battle.battleExecution!.battleReportStage!;
    battleExecutionData.winnerId = battle.battleExecution!.winnerId;
    battleExecutionData.reportFileId = battle.battleExecution!.reportFileId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            _getBattleExecution();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ChangeNotifierProvider(
                create: (context) => BattleExecutionData(BattleStatus.CREATED,
                    BattleReportStage.WAITING, null, null),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _getHeader(context),
                      _getStart(context),
                      _getProgressBar(context),
                      _getWinnerTag(context),
                      _getResult(context)
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
  }

  Widget _getHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.battleProcess,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getWinnerTag(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.winner,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getProgressBar(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          model.battleStatus == BattleStatus.CREATED
              ? const Icon(Icons.check_circle_outline,
                  size: 100, color: Colors.green)
              : const Icon(Icons.check_circle, size: 100),
          if (model.battleStatus == BattleStatus.CREATED ||
              model.battleStatus == BattleStatus.IN_PROGRESS)
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
          if (model.battleStatus == BattleStatus.FINISHED)
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
          if (model.battleStatus == BattleStatus.FAILED)
            ImageHelper.getSvgIconWithColor(
                'images/svgs/failed.svg', 100, 100, Colors.red),
        ],
      );
    });
  }

  Widget _getStart(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
                color: OnepieceColors.fancyBlue,
                width: 5,
                style: BorderStyle.solid),
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            child: Image.memory(
                Base64Helper.decode(battle.starter!.profileImage!)),
          ),
        ),
        _getStartButton(context),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
                color: OnepieceColors.fancyBlue,
                width: 5,
                style: BorderStyle.solid),
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            child: Image.memory(
                Base64Helper.decode(battle.receiver!.profileImage!)),
          ),
        ),
      ],
    );
  }

  Widget _getStartButton(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: IconButton(
          onPressed: model.battleStatus == BattleStatus.CREATED
              ? () {
                  getIt<BattleDao>()
                      .startBattle(StartBattleRequest(battleId: battle.id))
                      .then((value) => {
                            OnepieceAlert.getBasicAlertDialogFunc(
                                context, "battle", "start success")
                          });
                }
              : null,
          disabledColor: Colors.grey,
          splashRadius: 1,
          icon: SvgPicture.asset(
            'images/svgs/battle.svg',
            color: OnepieceColors.fancyBlue,
            width: 200,
            height: 200,
          ),
        ),
      );
    });
  }

  Widget _getResult(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return model.winnerId == null
          ? ImageHelper.getSvgIconWithColor(
              'images/svgs/question.svg', 200, 200, OnepieceColors.fancyBlue)
          : Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(
                    color: OnepieceColors.fancyBlue,
                    width: 5,
                    style: BorderStyle.solid),
              ),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Image.memory(
                  Base64Helper.decode(battle.starter!.id == model.winnerId
                      ? battle.starter!.profileImage!
                      : battle.receiver!.profileImage!),
                ),
              ),
            );
    });
  }
}

class BattleExecutionData extends ChangeNotifier {
  BattleStatus _battleStatus;
  BattleReportStage _battleReportStage;
  String? _reportFileId;
  String? _winnerId;

  BattleExecutionData(this._battleStatus, this._battleReportStage,
      this._reportFileId, this._winnerId);

  BattleStatus get battleStatus => _battleStatus;
  BattleReportStage get battleReportStage => _battleReportStage;
  String? get reportFileId => _reportFileId;
  String? get winnerId => _winnerId;

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
}
