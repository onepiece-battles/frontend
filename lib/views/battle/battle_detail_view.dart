import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import 'package:provider/provider.dart';

import '../../components/resource_loading.dart';
import '../../constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/pdf_downloader_stub.dart'
    if (dart.library.html) '../../utils/pdf_downloader_web.dart';
import 'battle_detail_controller.dart';
import 'battle_execution_data.dart';
import 'widgets/battle_detail_widgets.dart';

class BattleDetailView extends StatefulWidget {
  final String battleId;

  const BattleDetailView({super.key, required this.battleId});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  late final BattleDetailController _controller;
  final _scrollController = ScrollController();
  Timer? _timer;
  BattleFullView? _battle;
  BattleExecutionData? _execution;
  bool _loading = true;
  bool _failed = false;
  bool _polling = false;
  bool _starting = false;
  bool _downloading = false;
  bool _creatingRematch = false;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _controller = BattleDetailController();
    _loadBattle();
  }

  @override
  void didUpdateWidget(covariant BattleDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.battleId != widget.battleId) _loadBattle();
  }

  @override
  void dispose() {
    _loadVersion++;
    _timer?.cancel();
    _scrollController.dispose();
    _execution?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBattle() async {
    final version = ++_loadVersion;
    _timer?.cancel();
    final previousExecution = _execution;
    setState(() {
      _loading = true;
      _failed = false;
      _battle = null;
      _execution = null;
    });
    // Provider.value is removed on the next frame before its notifier is
    // disposed when a route reuses this widget for a different battle ID.
    if (previousExecution != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousExecution.dispose();
      });
    }
    try {
      final value = await _controller.getBattleFullView(
          GetBattleFullViewRequest(battleId: widget.battleId));
      if (!mounted || version != _loadVersion) return;
      final snapshot = value?.battleExecution;
      if (value?.starter == null ||
          value?.receiver == null ||
          snapshot?.battleStatus == null ||
          snapshot?.battleReportStage == null) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      final execution = BattleExecutionData(
        snapshot!.battleStatus!,
        snapshot.battleReportStage!,
        snapshot.reportFileId,
        snapshot.winnerId,
        snapshot.winnerScoreChange,
        snapshot.loserScoreChange,
        snapshot.starterScoreBefore,
        snapshot.starterScoreAfter,
        snapshot.receiverScoreBefore,
        snapshot.receiverScoreAfter,
      );
      setState(() {
        _battle = value;
        _execution = execution;
        _loading = false;
      });
      _startPolling();
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _startPolling() {
    _timer?.cancel();
    final model = _execution;
    if (model == null ||
        model.reportFileId != null ||
        model.battleStatus == BattleStatus.FAILED) {
      return;
    }
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _pollExecution());
  }

  Future<void> _pollExecution() async {
    if (_polling || _battle == null || _execution == null) return;
    final version = _loadVersion;
    _polling = true;
    try {
      final value = await _controller
          .getBattleExecution(GetBattleExecutionRequest(battleId: _battle!.id));
      if (!mounted || version != _loadVersion || value == null) return;
      final model = _execution!;
      final justFinished = model.battleStatus != BattleStatus.FINISHED &&
          value.battleStatus == BattleStatus.FINISHED;
      final reportJustArrived =
          model.reportFileId == null && value.reportFileId != null;
      if (value.battleStatus != null) model.battleStatus = value.battleStatus!;
      if (value.battleReportStage != null) {
        model.battleReportStage = value.battleReportStage!;
      }
      model.winnerId = value.winnerId;
      model.winnerScoreChange = value.winnerScoreChange;
      model.loserScoreChange = value.loserScoreChange;
      model.starterScoreBefore = value.starterScoreBefore;
      model.starterScoreAfter = value.starterScoreAfter;
      model.receiverScoreBefore = value.receiverScoreBefore;
      model.receiverScoreAfter = value.receiverScoreAfter;
      model.reportFileId = value.reportFileId;
      if (justFinished ||
          (reportJustArrived && _battle!.battleProcessDetails.isEmpty)) {
        _refreshRoundDetails(version);
      }
      if (model.reportFileId != null ||
          model.battleStatus == BattleStatus.FAILED) {
        _timer?.cancel();
      }
    } catch (_) {
      // A transient polling error should not erase the last known status.
    } finally {
      _polling = false;
    }
  }

  Future<void> _refreshRoundDetails(int version) async {
    try {
      final value = await _controller.getBattleFullView(
          GetBattleFullViewRequest(battleId: widget.battleId));
      if (!mounted || version != _loadVersion || value == null) return;
      setState(() => _battle = value);
    } catch (_) {
      // The current summary stays visible; a later page load can retry.
    }
  }

  Future<void> _startBattle() async {
    if (_starting || _battle == null || _execution == null) return;
    setState(() => _starting = true);
    try {
      await _controller.startBattle(StartBattleRequest(battleId: _battle!.id));
      if (!mounted) return;
      _execution!.battleStatus = BattleStatus.IN_PROGRESS;
      _startPolling();
      OnepieceAlert.createAlertShower(context)(
          AppLocalizations.of(context)!.battle,
          AppLocalizations.of(context)!.startSuccess);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _downloadReport() async {
    final fileId = _execution?.reportFileId;
    if (_downloading || fileId == null) return;
    setState(() => _downloading = true);
    try {
      final response =
          await _controller.downloadFile(DownloadFileRequest(id: fileId));
      if (!mounted) return;
      if (response?.fileData == null) {
        _showError();
        return;
      }
      final Uint8List pdf = base64Decode(response!.fileData!);
      downloadPdf(pdf, '${response.fileName}.pdf', response.httpMimeType);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _fightAgain() async {
    if (_creatingRematch || _battle == null) return;
    setState(() => _creatingRematch = true);
    try {
      final result = await _controller.createBattle(CreateBattleRequest(
        userId: GetIt.instance<User>().id,
        starterId: _battle!.starterId,
        receiverId: _battle!.receiverId,
      ));
      if (!mounted) return;
      final id = result?.battleId;
      if (id == null) {
        _showError();
        return;
      }
      context.goNamed('battleDetails', extra: id, pathParameters: {'id': id});
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _creatingRematch = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ResourceLoading();
    if (_failed || _battle == null || _execution == null) {
      return ResourceEmptyState(failed: true, onRetry: _loadBattle);
    }
    return ChangeNotifierProvider<BattleExecutionData>.value(
      value: _execution!,
      child: Consumer<BattleExecutionData>(
        builder: (context, model, _) => _buildStory(context, model),
      ),
    );
  }

  Widget _buildStory(BuildContext context, BattleExecutionData model) {
    final battle = _battle!;
    final loc = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      final outerPadding = constraints.maxWidth < 600 ? 16.0 : 28.0;
      return ColoredBox(
        color: const Color(0xFFF7F7F9),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(outerPadding, 22, outerPadding, 54),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(builder: (context, content) {
                  final sideBySide = content.maxWidth >= 800;
                  final rounds = _panel(
                    title: loc.battleRoundTitle,
                    child: BattleRounds(
                      key: ValueKey(battle.id),
                      details: battle.battleProcessDetails,
                      battleStatus: model.battleStatus,
                    ),
                  );
                  final report = _reportPanel(context, model);
                  return Column(
                    key: const Key('battle-story'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _navigation(context, battle),
                      const SizedBox(height: 22),
                      _heading(context, model),
                      const SizedBox(height: 22),
                      BattleDuel(
                        key: const Key('battle-duel'),
                        starter: battle.starter!,
                        receiver: battle.receiver!,
                        execution: model,
                        onCharacterTap: (character) {
                          context.goNamed('characterDetails',
                              extra: character.id,
                              pathParameters: {
                                'name': I18nHelper.getDisplayNameFromI18n(
                                    character.name)
                              });
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(loc.battleJourneyTitle,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.primaryLabel)),
                      const SizedBox(height: 17),
                      BattleJourney(
                          key: const Key('battle-journey'), execution: model),
                      const SizedBox(height: 28),
                      if (sideBySide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 13, child: rounds),
                            const SizedBox(width: 20),
                            Expanded(flex: 9, child: report),
                          ],
                        )
                      else ...[
                        rounds,
                        const SizedBox(height: 16),
                        report,
                      ],
                      const SizedBox(height: 20),
                      _abilityDisclosure(context, battle),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _navigation(BuildContext context, BattleFullView battle) {
    final loc = AppLocalizations.of(context)!;
    final previous = battle.previousBattle == null
        ? null
        : () => _goToBattle(battle.previousBattle!.id);
    final next = battle.nextBattle == null
        ? null
        : () => _goToBattle(battle.nextBattle!.id);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return Row(children: [
        Expanded(
          child: Text(loc.battle,
              style: const TextStyle(
                  fontSize: 12, color: OnepieceColors.secondaryLabel)),
        ),
        if (compact) ...[
          IconButton(
            tooltip: loc.previousBattle,
            onPressed: previous,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: loc.nextBattle,
            onPressed: next,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ] else ...[
          TextButton.icon(
            onPressed: previous,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: Text(loc.previousBattle),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: next,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: Text(loc.nextBattle),
          ),
        ],
      ]);
    });
  }

  void _goToBattle(String id) =>
      context.goNamed('battleDetails', extra: id, pathParameters: {'id': id});

  Widget _heading(BuildContext context, BattleExecutionData model) {
    final loc = AppLocalizations.of(context)!;
    final status = _statusLabel(loc, model);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Text(loc.battleDetailTitle,
            style: const TextStyle(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: OnepieceColors.primaryLabel)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: model.battleStatus == BattleStatus.FAILED
                  ? const Color(0xFFFFE9E7)
                  : OnepieceColors.fancyBlue.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(999)),
          child: Text(status,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: model.battleStatus == BattleStatus.FAILED
                      ? const Color(0xFFC64138)
                      : OnepieceColors.fancyBlue)),
        ),
        if (model.battleStatus == BattleStatus.CREATED)
          FilledButton.icon(
            onPressed: _starting ? null : _startBattle,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(loc.startBattle),
            style: FilledButton.styleFrom(
              backgroundColor: OnepieceColors.fancyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
          ),
      ],
    );
  }

  String _statusLabel(AppLocalizations loc, BattleExecutionData model) {
    if (model.battleStatus == BattleStatus.FAILED) {
      return loc.battleStatusFailed;
    }
    if (model.battleStatus == BattleStatus.CREATED) {
      return loc.battleStatusCreated;
    }
    if (model.battleStatus == BattleStatus.IN_PROGRESS) {
      return loc.battleStageFighting;
    }
    if (model.reportFileId != null) return loc.battleReportGenerated;
    if (model.battleReportStage == BattleReportStage.FINISHED) {
      return loc.battleReportPreparing;
    }
    if (model.battleReportStage == BattleReportStage.IN_PROGRESS) {
      return loc.battleReportInProgress;
    }
    return loc.battleStatusFinished;
  }

  Widget _reportPanel(BuildContext context, BattleExecutionData model) {
    final loc = AppLocalizations.of(context)!;
    final visitor = GetIt.instance<User>().loginRole == UserRole.VISITOR;
    final reportReady = model.battleReportStage == BattleReportStage.FINISHED &&
        model.reportFileId != null;
    final generating = model.battleReportStage ==
            BattleReportStage.IN_PROGRESS ||
        (model.battleReportStage == BattleReportStage.FINISHED && !reportReady);
    final failed = model.battleStatus == BattleStatus.FAILED;
    final description = failed
        ? loc.battleFailedDescription
        : reportReady
            ? visitor
                ? loc.battleReportVisitorDescription
                : loc.battleReportReadyDescription
            : generating
                ? loc.battleReportGeneratingDescription
                : loc.battleReportWaitingDescription;
    final label = failed
        ? loc.battleStatusFailed
        : reportReady
            ? loc.battleReportGenerated
            : generating
                ? loc.battleReportInProgress
                : loc.battleReportWaiting;
    return _panel(
      key: const Key('battle-report'),
      title: loc.battleReportTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: OnepieceColors.fancyBlue.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            if (generating && !failed)
              SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: MediaQuery.disableAnimationsOf(context) ? .5 : null,
                  color: OnepieceColors.fancyBlue,
                ),
              )
            else
              Icon(
                failed
                    ? Icons.error_outline_rounded
                    : reportReady
                        ? Icons.description_outlined
                        : Icons.schedule_rounded,
                size: 18,
                color: OnepieceColors.fancyBlue,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.fancyBlue)),
            ),
          ]),
        ),
        const SizedBox(height: 13),
        Text(description,
            style: const TextStyle(
                height: 1.5,
                fontSize: 13,
                color: OnepieceColors.secondaryLabel)),
        if (reportReady && !visitor) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _downloading ? null : _downloadReport,
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
                _downloading ? loc.battleReportPreparing : loc.downloadReport),
            style: FilledButton.styleFrom(
              backgroundColor: OnepieceColors.fancyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
        if (model.battleReportStage == BattleReportStage.FINISHED &&
            !visitor) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: _creatingRematch ? null : _fightAgain,
            child: Text(loc.fightAgain),
          ),
        ],
      ]),
    );
  }

  Widget _abilityDisclosure(BuildContext context, BattleFullView battle) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OnepieceColors.separator),
      ),
      child: ExpansionTile(
        title: Text(loc.battleAbilities,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: OnepieceColors.primaryLabel)),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Divider(height: 1, color: OnepieceColors.separator),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: Text(
                    I18nHelper.getDisplayNameFromI18n(battle.starter!.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))),
            Expanded(
                child: Text(
                    I18nHelper.getDisplayNameFromI18n(battle.receiver!.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12))),
          ]),
          BattleAbilityComparison(
              starter: battle.starter!, receiver: battle.receiver!),
        ],
      ),
    );
  }

  Widget _panel({Key? key, required String title, required Widget child}) =>
      Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OnepieceColors.separator),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: OnepieceColors.primaryLabel)),
          const SizedBox(height: 15),
          child,
        ]),
      );
}
