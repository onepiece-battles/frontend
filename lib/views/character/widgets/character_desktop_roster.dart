import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../components/resource_detail_layout.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import 'character_stat_pair.dart';

/// Desktop character roster: a responsive grid of spotlight cards, each
/// expandable to show the full stat grid, with a combat-power sort toggle.
/// Expand state and the score-sort action are owned by the parent and passed in.
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
            _buildScoreSortButton(context),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DesktopSpotlightGrid<CharacterListView>(
            items: characters,
            idOf: (character) => character.id,
            controller: scrollController,
            minCardWidth: 280,
            maxColumns: 6,
            gap: 10,
            cardBuilder: _buildCard,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSortButton(BuildContext context) {
    return DesktopSortChip(
      label: AppLocalizations.of(context)!.combatPower,
      ascending: scoreOrder == null ? null : scoreOrder == SortOrder.ASC,
      onTap: onScoreSortTap,
    );
  }

  Widget _buildCard(BuildContext context, CharacterListView character) {
    final race = raceMap[character.race] ?? '';
    final battleStyle = battleStyleMap[character.battleStyle] ?? '';
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.goNamed('characterDetails',
            extra: character.id,
            pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(character.name)
            }),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Hero(
                  tag: 'character-roster-${character.id}',
                  child: ImageLazyLoader(
                    key: ValueKey(character.imageUri),
                    uriProvider: () => character.imageUri ?? '',
                    width: 36,
                    borderWidth: 0,
                    borderRadios: 36,
                    lazy: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(I18nHelper.getDisplayNameFromI18n(character.name),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.primaryLabel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('$race · $battleStyle',
                          style: OnepieceFonts.smallContentStyle
                              .copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: OnepieceColors.secondaryLabel),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 14, runSpacing: 4, children: [
                Text.rich(TextSpan(
                  style: OnepieceFonts.smallContentStyle.copyWith(fontSize: 12),
                  children: [
                    TextSpan(text: '${loc.combatPower} '),
                    TextSpan(
                        text: '${character.score}',
                        style: const TextStyle(
                            color: OnepieceColors.primaryLabel,
                            fontWeight: FontWeight.w600)),
                  ],
                )),
                Text.rich(TextSpan(
                  style: OnepieceFonts.smallContentStyle.copyWith(fontSize: 12),
                  children: [
                    TextSpan(text: '${loc.bounty} '),
                    TextSpan(
                        text: '${character.bounty ?? '—'}',
                        style: OnepieceFonts.bountyStyle),
                  ],
                )),
              ]),
              const Divider(height: 1, color: OnepieceColors.separator),
              Row(children: [
                Expanded(
                    child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
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
                  onPressed: () => _openDetails(context, character),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(loc.detailInformation),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, CharacterListView character) {
    onToggleExpand(character.id);
    showResourceDetails(
            context,
            I18nHelper.getDisplayNameFromI18n(character.name),
            _buildStats(context, character))
        .whenComplete(() {
      if (context.mounted) onToggleExpand(character.id);
    });
  }

  Widget _buildStats(BuildContext context, CharacterListView character) {
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

    return DetailFieldGrid(
        fields:
            stats.map((stat) => DetailValue(stat.label, stat.value)).toList());
  }
}
