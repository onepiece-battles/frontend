import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';

/// The fruit list body: a card list on mobile, a spotlight grid on desktop.
/// Each card expands to show the strengthen coefficients. The expand state is
/// owned by the parent view and passed in via [expandedRowIds] /
/// [onToggleExpand].
class FruitRoster extends StatelessWidget {
  final List<FruitListView> fruits;
  final ScrollController controller;
  final Set<String> expandedRowIds;
  final void Function(String id) onToggleExpand;
  final bool isNarrow;

  const FruitRoster({
    super.key,
    required this.fruits,
    required this.controller,
    required this.expandedRowIds,
    required this.onToggleExpand,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  Map<FruitType, String> _typeMap(BuildContext context) => {
        FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
        FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
        FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
        FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
        FruitType.artificialZoan:
            AppLocalizations.of(context)!.artificialZoanFruit,
        FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
      };

  // ── Mobile: card-based fruit list ─────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final fruitTypeMap = _typeMap(context);

    if (fruits.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: fruits.length,
      itemBuilder: (context, index) {
        final fruit = fruits[index];
        final isExpanded = expandedRowIds.contains(fruit.id);
        final isEven = index.isEven;

        return Card(
          color: isEven ? OnepieceColors.liteFancyGreen : Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('fruitDetails',
                extra: fruit.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + type tag
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18nHelper.getDisplayNameFromI18n(fruit.name),
                          style:
                              OnepieceFonts.headerStyle.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OnepieceTag.getFruitTag(
                        fruit.fruitType!,
                        fruitTypeMap[fruit.fruitType]!,
                      ),
                    ],
                  ),
                  // Character list
                  if (fruit.characters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _createCharacterList(context, fruit.characters),
                  ],
                  // Expand toggle
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => onToggleExpand(fruit.id!),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.detailInformation,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: OnepieceColors.fancyBlue),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: OnepieceColors.fancyBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Expanded stats
                  if (isExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OnepieceColors.liteFancyGreen
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: <_FruitStat>[
                          _FruitStat(
                              AppLocalizations.of(context)!.attackStrengthen,
                              fruit.attackSlope!,
                              fruit.attackIntercept!,
                              'images/character_digits_icon/attack.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.defenseStrengthen,
                              fruit.defenseSlope!,
                              fruit.defenseIntercept!,
                              'images/character_digits_icon/defense.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.bloodStrengthen,
                              fruit.bloodSlope!,
                              fruit.bloodIntercept!,
                              'images/character_digits_icon/blood.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!
                                  .intelligenceStrengthen,
                              fruit.intelligenceSlope!,
                              fruit.intelligenceIntercept!,
                              'images/character_digits_icon/intelligence.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.groupStrengthen,
                              fruit.groupGainSlope!,
                              fruit.groupGainIntercept!,
                              'images/character_digits_icon/group_gain.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.speedStrengthen,
                              fruit.speedSlope!,
                              fruit.speedIntercept!,
                              'images/character_digits_icon/speed.svg'),
                        ].map((stat) {
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 80) / 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ImageHelper.getTextFormFieldIcon(
                                      stat.icon, true, 14),
                                ),
                                Text(stat.label,
                                    style: OnepieceFonts.smallContentStyle
                                        .copyWith(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('${stat.slope}x + ${stat.intercept}',
                                    style: OnepieceFonts.boldFancySmallFont
                                        .copyWith(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Desktop: spotlight grid ───────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (fruits.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }
    final typeMap = _typeMap(context);

    return DesktopSpotlightGrid<FruitListView>(
      items: fruits,
      idOf: (fruit) => fruit.id!,
      controller: controller,
      cardBuilder: (context, fruit) {
        final expanded = expandedRowIds.contains(fruit.id);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.goNamed('fruitDetails',
                extra: fruit.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        I18nHelper.getDisplayNameFromI18n(fruit.name),
                        style: OnepieceFonts.contentStyleBold.copyWith(
                            color: OnepieceColors.deepFancyBlue, fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OnepieceTag.getFruitTag(
                        fruit.fruitType!, typeMap[fruit.fruitType]!),
                  ]),
                  const SizedBox(height: 12),
                  if (fruit.characters.isNotEmpty)
                    SizedBox(
                        height: 44,
                        child: _createCharacterList(context, fruit.characters))
                  else
                    const SizedBox(height: 44),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => onToggleExpand(fruit.id!),
                      icon: Icon(expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label:
                          Text(AppLocalizations.of(context)!.detailInformation),
                    ),
                  ),
                  if (expanded)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FruitStat(
                            AppLocalizations.of(context)!.attackStrengthen,
                            fruit.attackSlope!,
                            fruit.attackIntercept!,
                            'images/character_digits_icon/attack.svg'),
                        _FruitStat(
                            AppLocalizations.of(context)!.defenseStrengthen,
                            fruit.defenseSlope!,
                            fruit.defenseIntercept!,
                            'images/character_digits_icon/defense.svg'),
                        _FruitStat(
                            AppLocalizations.of(context)!.bloodStrengthen,
                            fruit.bloodSlope!,
                            fruit.bloodIntercept!,
                            'images/character_digits_icon/blood.svg'),
                      ]
                          .map((stat) => Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: OnepieceColors.liteFancyGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    '${stat.label}: ${stat.slope}x + ${stat.intercept}',
                                    style:
                                        OnepieceFonts.superSmallContentStyle),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createCharacterList(
      BuildContext context, List<CharacterInFruitView> characters) {
    if (characters.isEmpty) {
      return const Text("");
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: characters
            .map((character) => InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    context.goNamed('characterDetails',
                        extra: character.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(
                              character.name)
                        });
                  },
                  child: Tooltip(
                    message: I18nHelper.getDisplayNameFromI18n(character.name),
                    preferBelow: false,
                    showDuration: const Duration(seconds: 1),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: ImageLazyLoader(
                            uriProvider: () => character.imageUri!,
                            width: 40,
                            borderWidth: 1.5,
                            borderRadios: 40)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _FruitStat {
  final String label;
  final double slope;
  final int intercept;
  final String icon;
  const _FruitStat(this.label, this.slope, this.intercept, this.icon);
}
