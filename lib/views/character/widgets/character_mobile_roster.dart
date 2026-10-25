import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import 'character_stat_pair.dart';

/// Mobile character roster: a scrollable list of compact character cards, each
/// expandable to show the full stat grid. The expand state is owned by the
/// parent and passed in via [expandedRowIds] / [onToggleExpand].
class CharacterMobileRoster extends StatelessWidget {
  final List<CharacterListView> characters;
  final ScrollController scrollController;
  final Map<BattleStyle, String> battleStyleMap;
  final Map<Race, String> raceMap;
  final Map<Haki, String> hakiMap;
  final Set<String> expandedRowIds;
  final void Function(String id) onToggleExpand;

  const CharacterMobileRoster({
    super.key,
    required this.characters,
    required this.scrollController,
    required this.battleStyleMap,
    required this.raceMap,
    required this.hakiMap,
    required this.expandedRowIds,
    required this.onToggleExpand,
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
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        final isExpanded = expandedRowIds.contains(character.id);
        final isEven = index.isEven;

        return Card(
          color: isEven ? OnepieceColors.liteFancyGreen : Colors.white,
          margin: const EdgeInsets.only(bottom: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('characterDetails',
                extra: character.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(character.name)
                }),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: image + name + score
                  Row(
                    children: [
                      ImageLazyLoader(
                        key: ValueKey(character.imageUri),
                        uriProvider: () => character.imageUri!,
                        width: 36,
                        borderWidth: 2,
                        lazy: true,
                        borderRadios: 36,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              I18nHelper.getDisplayNameFromI18n(character.name),
                              style: OnepieceFonts.headerStyle
                                  .copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${raceMap[character.race] ?? ""}  ·  ${battleStyleMap[character.battleStyle] ?? ""}',
                              style: OnepieceFonts.smallContentStyle
                                  .copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(character.score.toString(),
                              style: OnepieceFonts.boldFancySmallFont
                                  .copyWith(fontSize: 16)),
                          if (character.bounty != null && character.bounty! > 0)
                            Text(
                              '₿${character.bounty}',
                              style: GoogleFonts.lobster(
                                  fontSize: 12, color: Colors.orange[700]),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Row(children: [
                    Expanded(
                        child: Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: (character.hakis.toList()
                            ..sort((first, second) =>
                                first.toString().compareTo(second.toString())))
                          .map((haki) =>
                              OnepieceTag.getHakiTag(haki, hakiMap[haki] ?? ''))
                          .toList(),
                    )),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12)),
                      onPressed: () => onToggleExpand(character.id),
                      icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16),
                      label:
                          Text(AppLocalizations.of(context)!.detailInformation),
                    ),
                  ]),
                  // Expanded stats
                  if (isExpanded) _buildStatRows(context, character),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRows(BuildContext context, CharacterListView character) {
    final loc = AppLocalizations.of(context)!;
    final stats = <StatPair>[
      StatPair(loc.characterAttack, character.attack.toString(),
          icon: 'images/character_digits_icon/attack.svg'),
      StatPair(loc.characterDefense, character.defense.toString(),
          icon: 'images/character_digits_icon/defense.svg'),
      StatPair(loc.characterIntelligence, character.intelligence.toString(),
          icon: 'images/character_digits_icon/intelligence.svg'),
      StatPair(loc.characterBlood, character.blood.toString(),
          icon: 'images/character_digits_icon/blood.svg'),
      StatPair(loc.characterSpeed, character.speed.toString(),
          icon: 'images/character_digits_icon/speed.svg'),
      StatPair(loc.groupGain, character.groupGain.toString(),
          icon: 'images/character_digits_icon/group_gain.svg'),
      StatPair(loc.fruitLimit, character.maximumFruitCount.toString()),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: stats.map((stat) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 80) / 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stat.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        ImageHelper.getTextFormFieldIcon(stat.icon!, false, 14),
                  ),
                Text(stat.label,
                    style:
                        OnepieceFonts.smallContentStyle.copyWith(fontSize: 12)),
                const SizedBox(width: 4),
                Text(stat.value,
                    style: OnepieceFonts.boldFancySmallFont
                        .copyWith(fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
