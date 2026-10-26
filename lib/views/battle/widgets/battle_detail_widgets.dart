import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../battle_execution_data.dart';

/// A readable encounter summary. Combatants stack before their names become
/// narrow enough to wrap one character per line.
class BattleDuel extends StatelessWidget {
  const BattleDuel({
    super.key,
    required this.starter,
    required this.receiver,
    required this.execution,
    required this.onCharacterTap,
  });

  final Character starter;
  final Character receiver;
  final BattleExecutionData execution;
  final ValueChanged<Character> onCharacterTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 650;
          final left = _fighter(
            context,
            starter,
            execution.starterScoreBefore,
            execution.starterScoreAfter,
            execution.winnerId == starter.id,
          );
          final right = _fighter(
            context,
            receiver,
            execution.receiverScoreBefore,
            execution.receiverScoreAfter,
            execution.winnerId == receiver.id,
          );
          return Container(
            padding: EdgeInsets.all(stacked ? 16 : 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OnepieceColors.separator),
            ),
            child: stacked
                ? Column(children: [
                    left,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(AppLocalizations.of(context)!.versus,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.secondaryLabel)),
                    ),
                    right,
                  ])
                : Row(children: [
                    Expanded(child: left),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(AppLocalizations.of(context)!.versus,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.secondaryLabel)),
                    ),
                    Expanded(child: right),
                  ]),
          );
        },
      );

  Widget _fighter(BuildContext context, Character character, int? before,
      int? after, bool winner) {
    final name = I18nHelper.getDisplayNameFromI18n(character.name);
    final score = before == null
        ? '—'
        : after == null
            ? '$before'
            : '$before → $after';
    return InkWell(
      onTap: () => onCharacterTap(character),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          ImageLazyLoader(
            uriProvider: () => character.imageUri ?? '',
            width: 56,
            borderWidth: 0,
            borderRadios: 56,
            fullImage: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: OnepieceColors.primaryLabel)),
                const SizedBox(height: 5),
                Text('${AppLocalizations.of(context)!.combatPower}  $score',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: OnepieceColors.secondaryLabel)),
                if (winner) ...[
                  const SizedBox(height: 5),
                  Text(AppLocalizations.of(context)!.winner,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.fancyBlue)),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class BattleJourney extends StatelessWidget {
  const BattleJourney({super.key, required this.execution});
  final BattleExecutionData execution;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final status = execution.battleStatus;
    final finished = status == BattleStatus.FINISHED;
    final failed = status == BattleStatus.FAILED;
    final running = status == BattleStatus.IN_PROGRESS;
    final reportReady =
        execution.battleReportStage == BattleReportStage.FINISHED &&
            execution.reportFileId != null;
    final reportGenerating =
        execution.battleReportStage == BattleReportStage.IN_PROGRESS ||
            (execution.battleReportStage == BattleReportStage.FINISHED &&
                !reportReady);
    final steps = <_JourneyStep>[
      _JourneyStep(
          loc.battleStatusCreated,
          status == BattleStatus.CREATED
              ? _StepState.current
              : _StepState.done),
      _JourneyStep(
          failed ? loc.battleStatusFailed : loc.battleStageFighting,
          failed
              ? _StepState.failed
              : running
                  ? _StepState.current
                  : finished
                      ? _StepState.done
                      : _StepState.future),
      _JourneyStep(loc.battleResultConfirmed,
          finished ? _StepState.done : _StepState.future),
      _JourneyStep(
          reportGenerating
              ? loc.battleReportInProgress
              : loc.battleReportWaiting,
          finished
              ? reportReady
                  ? _StepState.done
                  : _StepState.current
              : _StepState.future),
      _JourneyStep(loc.battleReportGenerated,
          reportReady ? _StepState.done : _StepState.future),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final vertical = constraints.maxWidth < 700;
      return Semantics(
        label: loc.battleJourneyTitle,
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < steps.length; index++)
                    _verticalStep(steps[index], index == steps.length - 1),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in steps)
                    Expanded(child: _horizontalStep(step)),
                ],
              ),
      );
    });
  }

  Widget _marker(_JourneyStep step) {
    final isDone = step.state == _StepState.done;
    final isCurrent = step.state == _StepState.current;
    final isFailed = step.state == _StepState.failed;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? OnepieceColors.fancyBlue
            : isCurrent
                ? OnepieceColors.fancyBlue.withValues(alpha: .12)
                : isFailed
                    ? const Color(0xFFFFE9E7)
                    : OnepieceColors.surface,
      ),
      child: Icon(
        isDone
            ? Icons.check_rounded
            : isFailed
                ? Icons.close_rounded
                : isCurrent
                    ? Icons.more_horiz_rounded
                    : Icons.circle_outlined,
        size: isDone ? 15 : 13,
        color: isDone
            ? Colors.white
            : isFailed
                ? const Color(0xFFC64138)
                : isCurrent
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.secondaryLabel,
      ),
    );
  }

  Widget _horizontalStep(_JourneyStep step) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _marker(step),
            Expanded(
                child: Container(
                    height: 1,
                    color: step.state == _StepState.done
                        ? OnepieceColors.fancyBlue
                        : OnepieceColors.separator)),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(step.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: step.state == _StepState.future
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: step.state == _StepState.future
                        ? OnepieceColors.secondaryLabel
                        : OnepieceColors.primaryLabel)),
          ),
        ],
      );

  Widget _verticalStep(_JourneyStep step, bool last) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(children: [
              _marker(step),
              if (!last)
                Container(
                    width: 1,
                    height: 22,
                    color: step.state == _StepState.done
                        ? OnepieceColors.fancyBlue
                        : OnepieceColors.separator),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 20),
            child: Text(step.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: step.state == _StepState.future
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: step.state == _StepState.future
                        ? OnepieceColors.secondaryLabel
                        : OnepieceColors.primaryLabel)),
          )),
        ],
      );
}

enum _StepState { done, current, future, failed }

class _JourneyStep {
  const _JourneyStep(this.label, this.state);
  final String label;
  final _StepState state;
}

/// Uses the actual round payload. The API does not identify each attacker's
/// side, so no character is attributed to an individual attack.
class BattleRounds extends StatefulWidget {
  const BattleRounds({
    super.key,
    required this.details,
    required this.battleStatus,
  });

  final List<BattleProcessDetail> details;
  final BattleStatus battleStatus;

  @override
  State<BattleRounds> createState() => _BattleRoundsState();
}

class _BattleRoundsState extends State<BattleRounds> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (widget.details.isEmpty) {
      return Text(
        widget.battleStatus == BattleStatus.FINISHED ||
                widget.battleStatus == BattleStatus.FAILED
            ? loc.battleRoundNoData
            : loc.battleRoundsAfterFinish,
        style:
            const TextStyle(fontSize: 13, color: OnepieceColors.secondaryLabel),
      );
    }
    final rounds = [...widget.details]..sort((a, b) =>
        (a.battleProcessRoundNumber ?? 0)
            .compareTo(b.battleProcessRoundNumber ?? 0));
    final visible = _expanded ? rounds : rounds.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var index = 0; index < visible.length; index++) ...[
        if (index != 0)
          const Divider(height: 1, color: OnepieceColors.separator),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            final number = loc.battleRoundNumber(
                visible[index].battleProcessRoundNumber ?? index + 1);
            final content = _roundContent(context, visible[index]);
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(number, style: _numberStyle),
                        const SizedBox(height: 6),
                        content,
                      ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                        width: 95, child: Text(number, style: _numberStyle)),
                    Expanded(child: content),
                  ]);
          }),
        ),
      ],
      if (rounds.length > 5)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? loc.collapseRounds : loc.showAllRounds),
          ),
        ),
    ]);
  }

  static const _numberStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: OnepieceColors.fancyBlue);

  Widget _roundContent(BuildContext context, BattleProcessDetail round) {
    final loc = AppLocalizations.of(context)!;
    final facts = <String>[
      if (round.attackMissed != null)
        round.attackMissed! ? loc.battleAttackMissed : loc.battleAttackHit,
      if (round.defenderBloodLoss != null)
        '${loc.battleDamage} ${round.defenderBloodLoss}',
      if (round.attackerEnergyLoss != null)
        '${loc.battleEnergySpent} ${round.attackerEnergyLoss}',
      if (round.defenderEnergyLoss != null)
        '${loc.battleDefenderEnergyLost} ${round.defenderEnergyLoss}',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        round.attackSkill?.isNotEmpty == true
            ? '${loc.battleSkill}: ${round.attackSkill}'
            : loc.battleProcess,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: OnepieceColors.primaryLabel),
      ),
      if (facts.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(facts.join(' · '),
            style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: OnepieceColors.secondaryLabel)),
      ],
    ]);
  }
}

class BattleAbilityComparison extends StatelessWidget {
  const BattleAbilityComparison({
    super.key,
    required this.starter,
    required this.receiver,
  });

  final Character starter;
  final Character receiver;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final stats = <(String, int, int, int)>[
      (loc.characterAttack, starter.attack, receiver.attack, 1500),
      (loc.characterDefense, starter.defense, receiver.defense, 1400),
      (
        loc.characterIntelligence,
        starter.intelligence,
        receiver.intelligence,
        300
      ),
      (loc.characterSpeed, starter.speed, receiver.speed, 300),
      (loc.characterBlood, starter.blood, receiver.blood, 18000),
      (loc.characterEnergy, starter.energy, receiver.energy, 300),
    ];
    return Column(children: [
      for (final stat in stats)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            final bars = Column(children: [
              _bar(stat.$2, stat.$4, OnepieceColors.fancyBlue),
              const SizedBox(height: 5),
              _bar(stat.$3, stat.$4, OnepieceColors.secondaryLabel),
            ]);
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('${stat.$1}   ${stat.$2} / ${stat.$3}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 7),
                        bars,
                      ])
                : Row(children: [
                    SizedBox(
                        width: 110,
                        child: Text(stat.$1,
                            style: const TextStyle(fontSize: 12))),
                    Expanded(child: bars),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 88,
                        child: Text('${stat.$2} / ${stat.$3}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 12))),
                  ]);
          }),
        ),
    ]);
  }

  Widget _bar(int value, int max, Color color) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (value / max).clamp(0, 1).toDouble(),
          minHeight: 5,
          color: color,
          backgroundColor: OnepieceColors.surface,
        ),
      );
}

// Retain the existing helper signatures for callers outside the detail view.
@Deprecated('Use BattleDuel for the battle detail layout.')
Widget charMini(Character char, int? score) => Column(children: [
      ImageLazyLoader(
          uriProvider: () => char.imageUri ?? '',
          width: 52,
          borderWidth: 1.5,
          borderRadios: 52),
      const SizedBox(height: 2),
      Text(I18nHelper.getDisplayNameFromI18n(char.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11)),
      Text(score?.toString() ?? '?',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]);

@Deprecated('Use BattleJourney for the battle detail layout.')
Widget workflowConnector(bool active, double iconSize) => Padding(
      padding: EdgeInsets.only(left: iconSize / 2 - 1, top: 3, bottom: 3),
      child: Container(
        width: 2,
        height: iconSize * .7,
        decoration: BoxDecoration(
            color: active ? OnepieceColors.fancyBlue : OnepieceColors.separator,
            borderRadius: BorderRadius.circular(2)),
      ),
    );

@Deprecated('Use BattleJourney for the battle detail layout.')
Widget workflowStep({
  required String label,
  required bool done,
  required double iconSize,
  bool failed = false,
}) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
          failed
              ? Icons.error_rounded
              : done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
          size: iconSize,
          color: failed
              ? const Color(0xFFC64138)
              : done
                  ? OnepieceColors.fancyBlue
                  : OnepieceColors.secondaryLabel),
      const SizedBox(width: 10),
      Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: done
                      ? OnepieceColors.fancyBlue
                      : OnepieceColors.secondaryLabel))),
    ]);
