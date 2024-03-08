import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
import '../../constants/onepiece_fonts.dart';
import '../../utils/base64_helper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

GetIt getIt = GetIt.instance;

class BattleDetailView extends StatefulWidget {
  final String battleId;
  const BattleDetailView({super.key, required this.battleId});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  Timer? _timer;
  late BattleFullView battle;
  late BattleExecutionData battleExecutionData;
  late Character starter;
  late Character receiver;
  ValueNotifier<Uint8List?> pdfData = ValueNotifier(null);

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (battleExecutionData.reportFileId!=null) {
        return;
      }
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
        battle.battleExecution!.winnerId,
        battle.battleExecution!.winnerScoreChange,
        battle.battleExecution!.loserScoreChange,
        battle.battleExecution!.starterScoreBefore,
        battle.battleExecution!.starterScoreAfter,
        battle.battleExecution!.receiverScoreBefore,
        battle.battleExecution!.receiverScoreAfter);
    starter = battleFullView.starter!;
    receiver = battleFullView.receiver!;
  }

  void _updateBattleExecution(BattleExecution battleExecution) {
    battleExecutionData.battleStatus = battleExecution.battleStatus!;
    battleExecutionData.battleReportStage = battleExecution.battleReportStage!;
    battleExecutionData.winnerId = battleExecution.winnerId;
    battleExecutionData.reportFileId = battleExecution.reportFileId;
    battleExecutionData.starterScoreBefore = battleExecution.starterScoreBefore;
    battleExecutionData.starterScoreAfter = battleExecution.starterScoreAfter;
    battleExecutionData.receiverScoreBefore =
        battleExecution.receiverScoreBefore;
    battleExecutionData.receiverScoreAfter = battleExecution.receiverScoreAfter;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            _getBattleExecution();
            return Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ChangeNotifierProvider(
                        create: (context) => battleExecutionData,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 100,
                            ),
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
                            _getBattleReportIcon(context),
                            if (pdfData.value != null)
                              SizedBox(
                                  width: 1000,
                                  height: 1000,
                                  child: _getPdfView(context)),
                            // bottom space
                            const SizedBox(
                              height: 60,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Tooltip(
                            message: battle.previousBattle == null
                                ? ""
                                : "${I18nHelper.getDisplayNameFromI18n(battle.previousBattle!.starter!.name)} vs ${I18nHelper.getDisplayNameFromI18n(battle.previousBattle!.receiver!.name)}",
                            child: ElevatedButton(
                              onPressed: battle.previousBattle == null
                                  ? null
                                  : () {
                                      context.goNamed('battleDetails',
                                          extra: battle.previousBattle!.id,
                                          pathParameters: {
                                            'id': battle.previousBattle!.id
                                          });
                                    },
                              child: const Icon(Icons.arrow_back),
                            ),
                          ),
                          Tooltip(
                            message: battle.nextBattle == null
                                ? ""
                                : "${I18nHelper.getDisplayNameFromI18n(battle.nextBattle!.starter!.name)} vs ${I18nHelper.getDisplayNameFromI18n(battle.nextBattle!.receiver!.name)}",
                            child: ElevatedButton(
                              onPressed: battle.nextBattle == null
                                  ? null
                                  : () {
                                      context.goNamed('battleDetails',
                                          extra: battle.nextBattle!.id,
                                          pathParameters: {
                                            'id': battle.nextBattle!.id
                                          });
                                    },
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _getWinnerTag(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        AppLocalizations.of(context)!.winner,
        style: const TextStyle(
            color: OnepieceColors.fancyGreen,
            fontStyle: FontStyle.normal,
            fontSize: 20,
            fontWeight: FontWeight.bold),
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
                      Icon(Icons.check_circle,
                          size: iconSize, color: OnepieceColors.fancyBlue),
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
            InkWell(
              onTap: () {
                context.goNamed('characterDetails',
                    extra: starter.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(starter.name)
                    });
              },
              child: ImageHelper.getCircleImageFrame(
                  120,
                  120,
                  3,
                  OnepieceColors.liteFancyBlue,
                  Base64Helper.decode(battle.starter!.profileImage!)),
            ),
            Consumer<BattleExecutionData>(builder: (context, model, child) {
              return Column(
                children: [
                  Text(
                    I18nHelper.getDisplayNameFromI18n(starter.name),
                    style: OnepieceFonts.boldFancySmallFont,
                  ),
                  if (model.winnerId != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            model.starterScoreBefore.toString(),
                            style: OnepieceFonts.boldLiteFancySmallFont,
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: OnepieceColors.fancyBlue,
                            size: 10,
                          ),
                          Text(model.starterScoreAfter.toString(),
                              style: OnepieceFonts.boldFancySmallFont),
                        ],
                      ),
                    ),
                  if (model.winnerId == null)
                    Text(
                      battle.starter!.score.toString(),
                      style: OnepieceFonts.boldFancyBlueHintFont,
                    )
                ],
              );
            })
          ],
        ),
        _getStartButton(context),
        Column(
          children: [
            InkWell(
              onTap: () {
                context.goNamed('characterDetails',
                    extra: receiver.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(receiver.name)
                    });
              },
              child: ImageHelper.getCircleImageFrame(
                  120,
                  120,
                  3,
                  OnepieceColors.liteFancyBlue,
                  Base64Helper.decode(battle.receiver!.profileImage!)),
            ),
            Consumer<BattleExecutionData>(builder: (context, model, child) {
              return Column(
                children: [
                  Text(
                    I18nHelper.getDisplayNameFromI18n(receiver.name),
                    style: OnepieceFonts.boldFancySmallFont,
                  ),
                  if (model.winnerId != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            model.receiverScoreBefore.toString(),
                            style: OnepieceFonts.boldLiteFancySmallFont,
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: OnepieceColors.fancyBlue,
                            size: 10,
                          ),
                          Text(model.receiverScoreAfter.toString(),
                              style: OnepieceFonts.boldFancySmallFont),
                        ],
                      ),
                    ),
                  if (model.winnerId == null)
                    Text(
                      battle.receiver!.score.toString(),
                      style: OnepieceFonts.boldFancyBlueHintFont,
                    )
                ],
              );
            })
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
        padding: const EdgeInsets.all(40.0),
        child: Tooltip(
          message: model.battleStatus == BattleStatus.CREATED
              ? AppLocalizations.of(context)!.startBattle
              : "",
          child: InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: model.battleStatus == BattleStatus.CREATED
                ? () {
                    getIt<BattleDao>()
                        .startBattle(StartBattleRequest(battleId: battle.id))
                        .then((value) => {
                              OnepieceAlert.getBasicAlertDialogFunc(
                                  context, "battle", "start success")
                            });
                  }
                : null,
            child: SvgPicture.asset(
              'images/svgs/battle.svg',
              color: OnepieceColors.fancyBlue,
              width: 40,
              height: 40,
            ),
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
              child: ImageHelper.getSvgIconWithColor('images/svgs/question.svg',
                  120, 120, OnepieceColors.liteFancyBlue),
            )
          : ImageHelper.getCircleImageFrame(
              120,
              120,
              3,
              OnepieceColors.liteFancyBlue,
              Base64Helper.decode(battle.starter!.id == model.winnerId
                  ? battle.starter!.profileImage!
                  : battle.receiver!.profileImage!));
    });
  }

  String getScoreText(int scoreChange) {
    return scoreChange >= 0 ? "+ $scoreChange" : "- ${(0 - scoreChange)}";
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
                  model.winnerId != null
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: iconSize,
                  color: model.winnerId != null
                      ? OnepieceColors.fancyBlue
                      : OnepieceColors.liteFancyBlue,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.battleReportWaiting,
                    style: model.winnerId != null
                        ? OnepieceFonts.fancyBlueHintFont
                        : OnepieceFonts.liteFancyBlueHintFont,
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
                      Icon(Icons.check_circle,
                          size: iconSize, color: OnepieceColors.fancyBlue),
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
                      style: OnepieceFonts.fancyBlueHintFont,
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
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        child: Tooltip(
          message: model.battleReportStage == BattleReportStage.FINISHED
              ? AppLocalizations.of(context)!.downloadReport
              : "",
          child: InkWell(
            onTap: model.battleReportStage == BattleReportStage.FINISHED
                ? ()  {
                    getIt<FileDao>()
                        .downloadFile(DownloadFileRequest(
                            id: battleExecutionData.reportFileId!))
                        .then((value) async {
                          debugPrint('pdf downloading finish');
                      List<int> dataBytes = [];
                      // Listen for data transmitted and gather all bytes
                      await for (List<int> bytes in value!.finalize()) {
                        dataBytes.addAll(bytes);
                      }
                      pdfData.value = Uint8List.fromList(dataBytes);
                      final blob = html.Blob(dataBytes, 'application/pdf');
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      final anchor = html.AnchorElement()
                        ..href = url
                        ..style.display = 'none' // Ensure the element is not visible
                        ..download = "${value.filename}.pdf"; //

                      // Add the anchor element to the document body.
                      html.document.body?.append(anchor);

                      // Programmatically click the anchor element to start the download.
                      anchor.click();

                      // Remove the anchor element after the download has started.
                      anchor.remove();

                      // Release the object URL to free up resources.
                      html.Url.revokeObjectUrl(url);
                      //todo(yichi): download file from aliCloud oss.
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context, "battle", "download file success");
                    });
                  }
                : null,
            child: model.battleReportStage == BattleReportStage.FINISHED
                ? SvgPicture.asset(
                    'images/svgs/pdf.svg',
                    width: 100,
                    height: 100,
                  )
                : SvgPicture.asset(
                    'images/svgs/pdf_black.svg',
                    width: 100,
                    height: 100,
                    color: Colors.grey,
                  ),
          ),
        ),
      );
    });
  }

  Widget _getPdfView(BuildContext context) {
    return ValueListenableBuilder<Uint8List?>(
        valueListenable: pdfData,
        builder: (context, value, _) {
          return SfPdfViewer.memory(
            value!,
            key: _pdfViewerKey,
          );
        });
  }
}

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
