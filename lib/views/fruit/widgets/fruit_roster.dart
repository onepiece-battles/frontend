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
    if (fruits.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }
    return ListView.builder(
        controller: controller,
        itemCount: fruits.length,
        itemBuilder: (context, index) => Card(
              color:
                  index.isEven ? OnepieceColors.liteFancyGreen : Colors.white,
              margin: const EdgeInsets.only(bottom: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: _buildCard(context, fruits[index], true),
            ));
  }

  Widget _buildDesktop(BuildContext context) {
    if (fruits.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }
    return DesktopSpotlightGrid<FruitListView>(
        items: fruits,
        idOf: (fruit) => fruit.id!,
        controller: controller,
        minCardWidth: 280,
        maxColumns: 6,
        gap: 10,
        cardBuilder: (context, fruit) => _buildCard(context, fruit, false));
  }

  Widget _buildCard(BuildContext context, FruitListView fruit, bool mobile) {
    final loc = AppLocalizations.of(context)!;
    final typeMap = _typeMap(context);
    return Material(
      key: ValueKey('fruit-card-${fruit.id}'),
      color: mobile ? Colors.transparent : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.goNamed('fruitDetails',
            extra: fruit.id,
            pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(fruit.name)
            }),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 8 : 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: 28,
                child: Row(children: [
                  Expanded(
                      child: Text(I18nHelper.getDisplayNameFromI18n(fruit.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OnepieceFonts.contentStyleBold.copyWith(
                              fontSize: 14,
                              color: OnepieceColors.primaryLabel))),
                  const SizedBox(width: 8),
                  if (fruit.fruitType != null)
                    Flexible(
                        child: OnepieceTag.getFruitTag(
                            fruit.fruitType!, typeMap[fruit.fruitType] ?? '')),
                ])),
            const SizedBox(height: 6),
            SizedBox(
                height: 34,
                child: fruit.characters.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(loc.empty,
                            style: OnepieceFonts.superSmallContentStyle))
                    : _createCharacterList(context, fruit.characters)),
            const SizedBox(height: 6),
            const Divider(height: 1, color: OnepieceColors.separator),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(loc.detailInformation),
                  onPressed: () => _openDetails(context, fruit),
                )),
          ]),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, FruitListView fruit) {
    final loc = AppLocalizations.of(context)!;
    onToggleExpand(fruit.id!);
    showResourceDetails(
        context,
        I18nHelper.getDisplayNameFromI18n(fruit.name),
        DetailFieldGrid(fields: [
          DetailValue(loc.attackStrengthen,
              '${fruit.attackSlope}x + ${fruit.attackIntercept}'),
          DetailValue(loc.defenseStrengthen,
              '${fruit.defenseSlope}x + ${fruit.defenseIntercept}'),
          DetailValue(loc.bloodStrengthen,
              '${fruit.bloodSlope}x + ${fruit.bloodIntercept}'),
          DetailValue(loc.intelligenceStrengthen,
              '${fruit.intelligenceSlope}x + ${fruit.intelligenceIntercept}'),
          DetailValue(loc.speedStrengthen,
              '${fruit.speedSlope}x + ${fruit.speedIntercept}'),
          DetailValue(loc.groupStrengthen,
              '${fruit.groupGainSlope}x + ${fruit.groupGainIntercept}'),
          DetailValue(loc.energyConsume, '${fruit.energyConsume ?? '—'}'),
        ])).whenComplete(() {
      if (context.mounted) onToggleExpand(fruit.id!);
    });
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
                          'name':
                              I18nHelper.getDisplayNameFromI18n(character.name)
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
                            width: 24,
                            borderWidth: 1.5,
                            borderRadios: 40)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
