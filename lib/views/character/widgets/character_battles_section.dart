import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// Battle history from this character's point of view. Each row answers three
/// questions at a glance: who was the opponent, what happened, and how did the
/// character's battle rating change. More records expand in place on both
/// mobile and desktop; there is no horizontally scrolling table.
class CharacterBattlesSection extends StatefulWidget {
  final CharacterFullView character;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterBattlesSection({
    super.key,
    required this.character,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  State<CharacterBattlesSection> createState() =>
      _CharacterBattlesSectionState();
}

class _CharacterBattlesSectionState extends State<CharacterBattlesSection> {
  static const _batchSize = 10;
  int _visibleCount = _batchSize;

  @override
  void didUpdateWidget(covariant CharacterBattlesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _visibleCount = _batchSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final battles = widget.character.battles;
    final count = _visibleCount.clamp(0, battles.length);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OnepieceColors.separator),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Expanded(
              child: Text(loc.relatedBattles,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel)),
            ),
            Text(loc.relatedBattleCount(battles.length),
                style: const TextStyle(
                    fontSize: 11, color: OnepieceColors.secondaryLabel)),
          ]),
        ),
        if (battles.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Text(loc.characterBattleEmpty,
                style: const TextStyle(
                    fontSize: 13, color: OnepieceColors.secondaryLabel)),
          )
        else ...[
          const Divider(height: 1, color: OnepieceColors.separator),
          for (var index = 0; index < count; index++) ...[
            _battleRow(context, battles[index]),
            if (index < count - 1)
              const Divider(
                  height: 1, indent: 62, color: OnepieceColors.separator),
          ],
          if (count < battles.length || _visibleCount > _batchSize) ...[
            const Divider(height: 1, color: OnepieceColors.separator),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (count < battles.length)
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _visibleCount += _batchSize),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(loc.characterBattleShowMore),
                  ),
                if (_visibleCount > _batchSize)
                  TextButton.icon(
                    onPressed: () => setState(() => _visibleCount = _batchSize),
                    icon: const Icon(Icons.expand_less, size: 18),
                    label: Text(loc.characterBattleShowLess),
                  ),
              ]),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _battleRow(BuildContext context, BattleListView battle) {
    final loc = AppLocalizations.of(context)!;
    final ownId = widget.character.id;
    final isStarter = battle.starterId == ownId;
    final opponent = isStarter ? battle.receiver : battle.starter;
    final opponentName = opponent == null
        ? (isStarter ? loc.receiver : loc.initiator)
        : I18nHelper.getDisplayNameFromI18n(opponent.name);
    final execution = battle.battleExecution;
    final winnerId = execution?.winnerId;
    final won = winnerId != null && winnerId == ownId;
    final lost = winnerId != null && winnerId != ownId;
    final status = execution?.battleStatus;
    final outcome = _outcome(loc, status, won: won, lost: lost);
    final change = winnerId == null
        ? null
        : won
            ? execution?.winnerScoreChange
            : execution?.loserScoreChange;
    final before = isStarter
        ? execution?.starterScoreBefore
        : execution?.receiverScoreBefore;
    final after = isStarter
        ? execution?.starterScoreAfter
        : execution?.receiverScoreAfter;
    final number = NumberFormat.decimalPattern(
        Localizations.localeOf(context).languageCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed('battleDetails',
            extra: battle.id, pathParameters: {'id': battle.id}),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _avatar(opponent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opponentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.primaryLabel)),
                  const SizedBox(height: 3),
                  Text(_scoreLine(loc, number, before, after),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: OnepieceColors.secondaryLabel)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: outcome.color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(7)),
                child: Text(outcome.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: outcome.color)),
              ),
              if (change != null) ...[
                const SizedBox(height: 4),
                Text(
                    change >= 0
                        ? '+${number.format(change)}'
                        : '−${number.format(-change)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: change >= 0
                            ? const Color(0xFF247A50)
                            : const Color(0xFFB74B48))),
              ],
            ]),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right,
                size: 18, color: OnepieceColors.secondaryLabel),
          ]),
        ),
      ),
    );
  }

  Widget _avatar(Character? opponent) {
    final uri = opponent?.imageUri;
    if (uri == null || uri.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
            color: OnepieceColors.surface, shape: BoxShape.circle),
        child: const Icon(Icons.person_outline,
            size: 20, color: OnepieceColors.secondaryLabel),
      );
    }
    return ImageLazyLoader(
      key: ValueKey('battle-opponent-${opponent!.id}'),
      uriProvider: () => uri,
      width: 36,
      borderWidth: 0,
      borderRadios: 36,
      lazy: true,
    );
  }

  String _scoreLine(
      AppLocalizations loc, NumberFormat number, int? before, int? after) {
    if (before == null) return loc.combatPower;
    if (after == null) return '${loc.combatPower} ${number.format(before)}';
    return '${loc.combatPower} ${number.format(before)} → ${number.format(after)}';
  }

  ({String label, Color color}) _outcome(
      AppLocalizations loc, BattleStatus? status,
      {required bool won, required bool lost}) {
    if (won) {
      return (label: loc.characterBattleWin, color: const Color(0xFF247A50));
    }
    if (lost) {
      return (label: loc.characterBattleLoss, color: const Color(0xFFB74B48));
    }
    if (status == BattleStatus.FAILED) {
      return (label: loc.battleStatusFailed, color: const Color(0xFFB74B48));
    }
    if (status == BattleStatus.IN_PROGRESS) {
      return (label: loc.battleStatusStarted, color: OnepieceColors.fancyBlue);
    }
    if (status == BattleStatus.FINISHED) {
      return (
        label: loc.battleStatusFinished,
        color: OnepieceColors.secondaryLabel
      );
    }
    return (
      label: loc.battleStatusCreated,
      color: OnepieceColors.secondaryLabel
    );
  }
}
