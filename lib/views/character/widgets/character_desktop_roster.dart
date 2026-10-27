import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import 'character_roster_card.dart';

/// Desktop character grid. The parent owns each card's flipped state so it
/// remains stable while rows enter or leave the viewport.
class CharacterDesktopRoster extends StatelessWidget {
  final List<CharacterListView> characters;
  final int totalItemCount;
  final ScrollController scrollController;
  final Map<BattleStyle, String> battleStyleMap;
  final Map<Race, String> raceMap;
  final Map<Haki, String> hakiMap;
  final Set<String> expandedRowIds;
  final void Function(String id) onToggleExpand;
  final SortOrder? scoreOrder;
  final VoidCallback onScoreSortTap;
  final Widget? footer;

  const CharacterDesktopRoster({
    super.key,
    required this.characters,
    required this.totalItemCount,
    required this.scrollController,
    required this.battleStyleMap,
    required this.raceMap,
    required this.hakiMap,
    required this.expandedRowIds,
    required this.onToggleExpand,
    required this.scoreOrder,
    required this.onScoreSortTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.characterCount(totalItemCount),
              style: OnepieceFonts.smallContentStyle.copyWith(fontSize: 12),
            ),
            const Spacer(),
            DesktopSortChip(
              label: AppLocalizations.of(context)!.combatPower,
              ascending:
                  scoreOrder == null ? null : scoreOrder == SortOrder.ASC,
              onTap: onScoreSortTap,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DesktopSpotlightGrid<CharacterListView>(
            items: characters,
            idOf: (character) => character.id,
            controller: scrollController,
            minCardWidth: 315,
            maxColumns: 8,
            gap: 10,
            footer: footer,
            cardBuilder: (context, character) => CharacterRosterCard(
              key: ValueKey('character-card-${character.id}'),
              character: character,
              battleStyleMap: battleStyleMap,
              raceMap: raceMap,
              hakiMap: hakiMap,
              flipped: expandedRowIds.contains(character.id),
              onFlip: () => onToggleExpand(character.id),
            ),
          ),
        ),
      ],
    );
  }
}
