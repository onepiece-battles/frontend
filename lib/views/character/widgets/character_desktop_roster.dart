import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
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
              '$totalItemCount ${AppLocalizations.of(context)!.character}',
              style: OnepieceFonts.smallContentStyle,
            ),
            const Spacer(),
            _buildScoreSortButton(context),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 18.0;
                  final columnCount =
                      (constraints.maxWidth / 340).floor().clamp(2, 5);
                  final cardWidth =
                      (constraints.maxWidth - gap * (columnCount - 1)) /
                          columnCount;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: characters
                        .map((character) => SizedBox(
                              width: cardWidth,
                              child: _buildCard(context, character),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSortButton(BuildContext context) {
    final isActive = scoreOrder != null;
    return Tooltip(
      message: AppLocalizations.of(context)!.combatPower,
      child: InkWell(
        onTap: onScoreSortTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? OnepieceColors.fancyBlue.withValues(alpha: 0.10)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? OnepieceColors.fancyBlue.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 17, color: OnepieceColors.fancyBlue),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context)!.combatPower,
                style: OnepieceFonts.smallContentStyle.copyWith(
                  color: isActive ? OnepieceColors.fancyBlue : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                scoreOrder == SortOrder.ASC
                    ? Icons.arrow_upward
                    : scoreOrder == SortOrder.DESC
                        ? Icons.arrow_downward
                        : Icons.unfold_more,
                size: 15,
                color: isActive ? OnepieceColors.fancyBlue : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, CharacterListView character) {
    final isExpanded = expandedRowIds.contains(character.id);
    final race = raceMap[character.race] ?? '';
    final battleStyle = battleStyleMap[character.battleStyle] ?? '';

    return DesktopSpotlightCard(
      key: ValueKey('character-card-${character.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.goNamed(
              'characterDetails',
              extra: character.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(character.name)
              },
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'character-roster-${character.id}',
                        child: ImageLazyLoader(
                          key: ValueKey(character.imageUri),
                          uriProvider: () => character.imageUri!,
                          width: 58,
                          borderWidth: 2,
                          borderRadios: 58,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              I18nHelper.getDisplayNameFromI18n(character.name),
                              style: OnepieceFonts.contentStyleBold.copyWith(
                                color: OnepieceColors.deepFancyBlue,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.public,
                                    size: 14, color: Colors.black45),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$race · $battleStyle',
                                    style: OnepieceFonts.smallContentStyle
                                        .copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              OnepieceColors.fancyBlue,
                              OnepieceColors.deepFancyBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.bolt,
                                size: 14, color: Colors.white70),
                            Text(
                              character.score.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (character.hakis.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: (character.hakis.toList()
                            ..sort(
                                (a, b) => a.toString().compareTo(b.toString())))
                          .map((haki) =>
                              OnepieceTag.getHakiTag(haki, hakiMap[haki]!))
                          .toList(),
                    )
                  else
                    const SizedBox(height: 20),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: OnepieceColors.liteFancyGreen,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.paid_outlined,
                            size: 17, color: Colors.orange[800]),
                        const SizedBox(width: 5),
                        Text(
                          character.bounty?.toString() ?? '—',
                          style: GoogleFonts.lobster(
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => onToggleExpand(character.id),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .detailInformation,
                                  style: OnepieceFonts.boldFancySmallFont,
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: OnepieceColors.fancyBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildStats(context, character),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats
            .map(
              (stat) => Container(
                width: 102,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    if (stat.icon != null) ...[
                      ImageHelper.getTextFormFieldIcon(stat.icon!, false, 14),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        stat.label,
                        style: OnepieceFonts.superSmallContentStyle
                            .copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      stat.value,
                      style: OnepieceFonts.boldFancySmallFont,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
