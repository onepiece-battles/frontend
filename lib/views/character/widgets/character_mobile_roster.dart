import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import 'character_roster_card.dart';

/// Mobile character list using the same two-sided card as the desktop grid.
class CharacterMobileRoster extends StatelessWidget {
  final List<CharacterListView> characters;
  final ScrollController scrollController;
  final Map<BattleStyle, String> battleStyleMap;
  final Map<Race, String> raceMap;
  final Map<Haki, String> hakiMap;
  final Set<String> expandedRowIds;
  final void Function(String id) onToggleExpand;
  final Widget? footer;

  const CharacterMobileRoster({
    super.key,
    required this.characters,
    required this.scrollController,
    required this.battleStyleMap,
    required this.raceMap,
    required this.hakiMap,
    required this.expandedRowIds,
    required this.onToggleExpand,
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
    return ListView.builder(
      controller: scrollController,
      itemCount: characters.length + (footer == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == characters.length) return footer!;
        final character = characters[index];
        return Card(
          key: ValueKey('character-card-${character.id}'),
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: OnepieceColors.separator),
          ),
          child: CharacterRosterCard(
            character: character,
            battleStyleMap: battleStyleMap,
            raceMap: raceMap,
            hakiMap: hakiMap,
            flipped: expandedRowIds.contains(character.id),
            onFlip: () => onToggleExpand(character.id),
          ),
        );
      },
    );
  }
}
