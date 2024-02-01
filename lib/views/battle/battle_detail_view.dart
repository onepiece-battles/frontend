import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/graph/character_bar_graph.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:provider/provider.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/graph/character_data.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_fonts.dart';
import '../../graph/individual_bar.dart';
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
            return Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ChangeNotifierProvider(
                  create: (context) => BattleExecutionData(BattleStatus.CREATED,
                      BattleReportStage.WAITING, null, null),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // _getHeader(context),
                        _getStart(context),
                        const SizedBox(
                          width: 400,
                          child: Divider(
                            color: OnepieceColors.fancyBlue,
                            thickness: 2,
                            height: 20,
                          ),
                        ),
                        _getProgressBar(context, 40),
                        const SizedBox(
                          width: 400,
                          child: Divider(
                            color: OnepieceColors.fancyBlue,
                            thickness: 2,
                            height: 20,
                          ),
                        ),
                        _getWinnerTag(context),
                        _getResult(context),
                        const SizedBox(
                          width: 400,
                          child: Divider(
                            color: OnepieceColors.fancyBlue,
                            thickness: 2,
                            height: 20,
                          ),
                        ),
                        _getBattleReportProgress(context, 40),
                        const SizedBox(
                          width: 400,
                          child: Divider(
                            color: OnepieceColors.fancyBlue,
                            thickness: 2,
                            height: 20,
                          ),
                        ),
                        _getBattleReportIcon(context)
                      ],
                    ),
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
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child:  Text(
        AppLocalizations.of(context)!.winner,
        style: const TextStyle(
          color: OnepieceColors.fancyGreen,
          fontStyle: FontStyle.normal,
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _getProgressBar(BuildContext context, double iconSize) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: iconSize,
                  color: OnepieceColors.fancyBlue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.battleStatusCreated,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0),
              child: Text(
                "|",
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
            model.battleStatus == BattleStatus.CREATED
                ? Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: iconSize, color: OnepieceColors.liteFancyBlue),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.battleInProgress,
                          style: OnepieceFonts.liteFancyBlueHintFont,
                        ),
                      )
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.check_circle, size: iconSize),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.battleInProgress,
                          style: OnepieceFonts.fancyBlueHintFont,
                        ),
                      )
                    ],
                  ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0),
              child: Text(
                "|",
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
            if (model.battleStatus == BattleStatus.CREATED ||
                model.battleStatus == BattleStatus.IN_PROGRESS)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: iconSize,
                    color: OnepieceColors.liteFancyBlue,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.battleFinished,
                      style: OnepieceFonts.liteFancyBlueHintFont,
                    ),
                  )
                ],
              ),
            if (model.battleStatus == BattleStatus.FINISHED)
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: iconSize, color: OnepieceColors.fancyBlue),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.battleStatusFinished,
                      style: OnepieceFonts.fancyBlueHintFont,
                    ),
                  )
                ],
              ),
            if (model.battleStatus == BattleStatus.FAILED)
              Row(
                children: [
                  ImageHelper.getSvgIconWithColor(
                      'images/svgs/failed.svg', iconSize, iconSize, Colors.red),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.battleStatusFailed,
                      style: OnepieceFonts.liteFancyBlueHintFont,
                    ),
                  )
                ],
              ),
          ],
        ),
      );
    });
  }


  Widget _getStart(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: CharacterBarGraph(
                    characterData: CharacterData(
                  battle.starter!.attack,
                  battle.starter!.defense,
                  battle.starter!.intelligence,
                  battle.starter!.speed,
                  battle.starter!.blood,
                  battle.starter!.energy,
                )),
              ),
            ),
          ),
        ),
        Column(
          children: [
            Container(
              width: 120,
              height: 120,
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
            Text(
              I18nHelper.getDisplayNameFromI18n(starter.name),
              style: OnepieceFonts.fancyBlueHintFont,
            )
          ],
        ),
        _getStartButton(context),
        Column(
          children: [
            Container(
              width: 120,
              height: 120,
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
            Text(
              I18nHelper.getDisplayNameFromI18n(receiver.name),
              style: OnepieceFonts.fancyBlueHintFont,
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: CharacterBarGraph(
                    characterData: CharacterData(
                  battle.receiver!.attack,
                  battle.receiver!.defense,
                  battle.receiver!.intelligence,
                  battle.receiver!.speed,
                  battle.receiver!.blood,
                  battle.receiver!.energy,
                )),
              ),
            ),
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
          iconSize: 50,
          tooltip: AppLocalizations.of(context)!.startBattle,
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
            color: OnepieceColors.fancyGreen,
            width: 500,
            height: 500,
          ),
        ),
      );
    });
  }

  Widget _getResult(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return model.winnerId == null
          ? Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: ImageHelper.getSvgIconWithColor('images/svgs/question.svg', 120,
                120, OnepieceColors.liteFancyBlue),
          )
          : Container(
              width: 120,
              height: 120,
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

  Widget _getBattleReportProgress(BuildContext context, double iconSize) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: iconSize,
                  color: OnepieceColors.fancyBlue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.battleReportWaiting,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0),
              child: Text(
                "|",
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
            model.battleReportStage == BattleReportStage.WAITING
                ? Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: iconSize, color: OnepieceColors.liteFancyBlue),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.battleReportInProgress,
                    style: OnepieceFonts.liteFancyBlueHintFont,
                  ),
                )
              ],
            )
                : Row(
              children: [
                Icon(Icons.check_circle, size: iconSize),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.battleReportInProgress,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0),
              child: Text(
                "|",
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
            if (model.battleReportStage == BattleReportStage.WAITING ||
                model.battleReportStage == BattleReportStage.IN_PROGRESS)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: iconSize,
                    color: OnepieceColors.liteFancyBlue,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.battleReportGenerated,
                      style: OnepieceFonts.liteFancyBlueHintFont,
                    ),
                  )
                ],
              ),
            if (model.battleReportStage == BattleReportStage.FINISHED)
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: iconSize, color: OnepieceColors.fancyBlue),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.battleReportGenerated,
                      style: OnepieceFonts.liteFancyBlueHintFont,
                    ),
                  )
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _getBattleReportIcon(BuildContext context) {
    return IconButton(
      iconSize: 50,
      tooltip: AppLocalizations.of(context)!.downloadReport,
      onPressed: battleExecutionData.battleReportStage   == BattleReportStage.FINISHED
          ? () {
        getIt<FileDao>()
            .downloadFile(DownloadFileRequest(id: battleExecutionData.reportFileId!))
            .then((value) => {
          OnepieceAlert.getBasicAlertDialogFunc(
              context, "battle", "download file success")
        });
      }: null,
      disabledColor: Colors.grey,
      splashRadius: 1,
      icon: SvgPicture.asset(
        'images/svgs/pdf.svg',
        width: 500,
        height: 500,
      ),
    );
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

