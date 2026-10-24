import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/graph/character_bar_graph.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:provider/provider.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'battle_detail_controller.dart';
import 'battle_execution_data.dart';
import 'widgets/battle_detail_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/graph/character_data.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/pdf_downloader_stub.dart'
    if (dart.library.html) '../../utils/pdf_downloader_web.dart';

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
  ValueNotifier<Uint8List?> pdfData = ValueNotifier(null);
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final BattleDetailController _controller = BattleDetailController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    _pageScrollController.dispose();
    _horizontalScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  _loadData() {
    return _controller
        .getBattleFullView(GetBattleFullViewRequest(battleId: widget.battleId));
  }

  _getBattleExecution() {
    _timer?.cancel();
    GetBattleExecutionRequest request =
        GetBattleExecutionRequest(battleId: battle.id);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (battleExecutionData.reportFileId != null) {
        return;
      }
      _controller
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

  String _statusText() {
    final statusMap = <BattleStatus, String>{
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return statusMap[battle.battleExecution?.battleStatus] ?? '';
  }

  void _startBattle(BuildContext context) {
    final battleTitle = AppLocalizations.of(context)!.battle;
    final startSuccess = AppLocalizations.of(context)!.startSuccess;
    final showAlert = OnepieceAlert.createAlertShower(context);
    _controller
        .startBattle(StartBattleRequest(battleId: battle.id))
        .then((value) {
      if (!mounted) return;
      battleExecutionData.battleStatus = BattleStatus.IN_PROGRESS;
      showAlert(battleTitle, startSuccess);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            _getBattleExecution();
            return ChangeNotifierProvider.value(
              value: battleExecutionData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow =
                      ResponsiveBreakpoints.isMobileFromConstraints(
                          constraints);
                  return Stack(
                    children: [
                      if (isNarrow)
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          child: Column(children: [
                            Center(
                                child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                  color: OnepieceColors.fancyBlue
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(_statusText(),
                                  style: OnepieceFonts.headerStyle.copyWith(
                                      color: OnepieceColors.fancyBlue,
                                      fontSize: 15)),
                            )),
                            _getStartButton(context, compact: true),
                            const SizedBox(height: 12),
                            Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(children: [
                                      Row(children: [
                                        Expanded(
                                            child: charMini(
                                                battle.starter!,
                                                battle.battleExecution
                                                    ?.starterScoreBefore)),
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Column(children: [
                                              Text('VS',
                                                  style: TextStyle(
                                                      color: OnepieceColors
                                                          .fancyBlue,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ])),
                                        Expanded(
                                            child: charMini(
                                                battle.receiver!,
                                                battle.battleExecution
                                                    ?.receiverScoreBefore)),
                                      ]),
                                      _getProgressBar(context, 22),
                                      const SizedBox(height: 10),
                                      _getWinnerTag(context),
                                      const SizedBox(height: 6),
                                      _getResult(context),
                                    ]))),
                            const SizedBox(height: 10),
                            Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RepaintBoundary(
                                        child: Column(children: [
                                      Center(
                                          child: _getBattleReportProgress(
                                              context, 28)),
                                      Center(
                                          child: _getBattleReportIcon(context)),
                                    ])))),
                            if (getIt<User>().loginRole !=
                                UserRole.VISITOR) ...[
                              const SizedBox(height: 10),
                              _getFightAgain(context)
                            ],
                          ]),
                        )
                      else
                        SingleChildScrollView(
                          controller: _pageScrollController,
                          scrollDirection: Axis.vertical,
                          child: Center(
                            child: NestedHorizontalScrollView(
                              controller: _horizontalScrollController,
                              verticalParentController: _pageScrollController,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 100),
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
                                  if (getIt<User>().loginRole !=
                                      UserRole.VISITOR)
                                    _getFightAgain(context),
                                  // bottom space
                                  const SizedBox(
                                    height: 60,
                                  )
                                ],
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
                                ElevatedButton(
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
                                ElevatedButton(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
      final isCreated = model.battleStatus == BattleStatus.CREATED;
      final isInProgress = model.battleStatus == BattleStatus.IN_PROGRESS;
      final isFinished = model.battleStatus == BattleStatus.FINISHED;
      final isFailed = model.battleStatus == BattleStatus.FAILED;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnepieceColors.separator),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              workflowStep(
                label: AppLocalizations.of(context)!.battleStatusCreated,
                done: true,
                iconSize: iconSize,
              ),
              workflowConnector(!isCreated, iconSize),
              workflowStep(
                label: AppLocalizations.of(context)!.battleInProgress,
                done: isInProgress || isFinished || isFailed,
                iconSize: iconSize,
                failed: isFailed,
              ),
              workflowConnector(isFinished || isFailed, iconSize),
              workflowStep(
                label: isFailed
                    ? AppLocalizations.of(context)!.battleStatusFailed
                    : AppLocalizations.of(context)!.battleFinished,
                done: isFinished || isFailed,
                iconSize: iconSize,
                failed: isFailed,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _getStartButton(BuildContext context, {bool compact = false}) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      if (model.battleStatus != BattleStatus.CREATED) {
        return compact
            ? const SizedBox.shrink()
            : const SizedBox(
                width: 35,
              );
      }

      if (compact) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ElevatedButton.icon(
            onPressed: () => _startBattle(context),
            icon: const Icon(Icons.not_started, size: 18),
            label: Text(AppLocalizations.of(context)!.startBattle),
            style: ElevatedButton.styleFrom(
              backgroundColor: OnepieceColors.fancyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () => _startBattle(context),
            child: const Icon(
              Icons.not_started,
              size: 55,
              color: OnepieceColors.fancyBlue,
            )),
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
                    symmetric: false,
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
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  context.goNamed('characterDetails',
                      extra: starter.id,
                      pathParameters: {
                        'name': I18nHelper.getDisplayNameFromI18n(starter.name)
                      });
                },
                child: ImageLazyLoader(
                    uriProvider: () => battle.starter!.imageUri!,
                    width: 120,
                    borderWidth: 3,
                    borderRadios: 120)),
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
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  context.goNamed('characterDetails',
                      extra: receiver.id,
                      pathParameters: {
                        'name': I18nHelper.getDisplayNameFromI18n(receiver.name)
                      });
                },
                child: ImageLazyLoader(
                    uriProvider: () => battle.receiver!.imageUri!,
                    width: 120,
                    borderWidth: 3,
                    borderRadios: 120)),
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
                    symmetric: false,
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

  Widget _getResult(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return model.winnerId == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ImageHelper.getSvgIconWithColor('images/svgs/question.svg',
                  120, 120, OnepieceColors.liteFancyBlue),
            )
          : ImageLazyLoader(
              uriProvider: () => battle.starter!.id == model.winnerId
                  ? battle.starter!.imageUri!
                  : battle.receiver!.imageUri!,
              width: 120,
              borderWidth: 3,
              borderRadios: 120,
              fullImage: true);
    });
  }

  String getScoreText(int scoreChange) {
    return scoreChange >= 0 ? "+ $scoreChange" : "- ${(0 - scoreChange)}";
  }

  Widget _getBattleReportProgress(BuildContext context, double iconSize) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      final hasWinner = model.winnerId != null;
      final isGenerating =
          model.battleReportStage == BattleReportStage.IN_PROGRESS;
      final isFinished = model.battleReportStage == BattleReportStage.FINISHED;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnepieceColors.separator),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              workflowStep(
                label: AppLocalizations.of(context)!.battleReportWaiting,
                done: hasWinner,
                iconSize: iconSize,
              ),
              workflowConnector(isGenerating || isFinished, iconSize),
              workflowStep(
                label: AppLocalizations.of(context)!.battleReportInProgress,
                done: isGenerating || isFinished,
                iconSize: iconSize,
              ),
              workflowConnector(isFinished, iconSize),
              workflowStep(
                label: AppLocalizations.of(context)!.battleReportGenerated,
                done: isFinished,
                iconSize: iconSize,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _getBattleReportIcon(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      final canDownload =
          model.battleReportStage == BattleReportStage.FINISHED &&
              getIt<User>().loginRole != UserRole.VISITOR;
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 18),
        child: InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: canDownload
              ? () {
                  _controller
                      .downloadFile(DownloadFileRequest(
                          id: battleExecutionData.reportFileId!))
                      .then((response) async {
                    if (response?.fileData == null) return;
                    var pdf = base64Decode(response!.fileData!);
                    downloadPdf(
                        pdf, "${response.fileName}.pdf", response.httpMimeType);
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canDownload
                  ? OnepieceColors.fancyBlue.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: canDownload
                    ? OnepieceColors.fancyBlue.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.25),
              ),
            ),
            child: SvgPicture.asset(
              canDownload
                  ? 'asset/images/svgs/pdf.svg'
                  : 'asset/images/svgs/pdf_black.svg',
              width: 72,
              height: 72,
              colorFilter: canDownload
                  ? null
                  : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
          ),
        ),
      );
    });
  }

  Widget _getFightAgain(BuildContext context) {
    return Consumer<BattleExecutionData>(builder: (context, model, child) {
      return model.battleReportStage == BattleReportStage.FINISHED
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    _controller
                        .createBattle(CreateBattleRequest(
                            userId: getIt<User>().id,
                            starterId: battle.starterId,
                            receiverId: battle.receiverId))
                        .then((value) {
                      if (!mounted) return;
                      router.goNamed('battleDetails',
                          extra: value!.battleId,
                          pathParameters: {'id': value.battleId!});
                    });
                  },
                  child: Text(
                    AppLocalizations.of(context)!.fightAgain,
                    style: OnepieceFonts.boldFancySmallFont,
                  )),
            )
          : const SizedBox(
              height: 10,
            );
    });
  }
}
