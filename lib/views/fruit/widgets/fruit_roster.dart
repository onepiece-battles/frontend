import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../components/resource_flip_card.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// Two-sided fruit cards for both responsive list layouts. Flipped state is
/// owned by the parent so scrolling a card out of view does not reset it.
class FruitRoster extends StatelessWidget {
  final List<FruitListView> fruits;
  final ScrollController controller;
  final Set<String> expandedRowIds;
  final void Function(String id) onToggleExpand;
  final bool isNarrow;
  final Widget? footer;

  const FruitRoster({
    super.key,
    required this.fruits,
    required this.controller,
    required this.expandedRowIds,
    required this.onToggleExpand,
    required this.isNarrow,
    this.footer,
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

  Widget _buildMobile(BuildContext context) {
    if (fruits.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }
    return ListView.builder(
      controller: controller,
      itemCount: fruits.length + (footer == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == fruits.length) return footer!;
        final fruit = fruits[index];
        return Card(
          key: ValueKey('fruit-card-${fruit.id}'),
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: OnepieceColors.separator),
          ),
          child: _buildCard(context, fruit),
        );
      },
    );
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
      gap: 12,
      footer: footer,
      cardBuilder: _buildCard,
    );
  }

  void _open(BuildContext context, FruitListView fruit) => context.goNamed(
      'fruitDetails',
      extra: fruit.id,
      pathParameters: {'name': I18nHelper.getDisplayNameFromI18n(fruit.name)});

  Widget _buildCard(BuildContext context, FruitListView fruit) {
    final loc = AppLocalizations.of(context)!;
    final name = I18nHelper.getDisplayNameFromI18n(fruit.name);
    void onFlip() => onToggleExpand(fruit.id!);
    return ResourceFlipCard(
      key: ValueKey('fruit-flip-${fruit.id}'),
      flipped: expandedRowIds.contains(fruit.id),
      front: _front(context, fruit, name, loc, onFlip),
      back: ResourceFlipDetail(
        title: name,
        onFlipBack: onFlip,
        onOpen: () => _open(context, fruit),
        fields: [
          ResourceFlipField(loc.attackStrengthen,
              _formula(fruit.attackSlope, fruit.attackIntercept)),
          ResourceFlipField(loc.defenseStrengthen,
              _formula(fruit.defenseSlope, fruit.defenseIntercept)),
          ResourceFlipField(loc.bloodStrengthen,
              _formula(fruit.bloodSlope, fruit.bloodIntercept)),
          ResourceFlipField(loc.intelligenceStrengthen,
              _formula(fruit.intelligenceSlope, fruit.intelligenceIntercept)),
          ResourceFlipField(loc.speedStrengthen,
              _formula(fruit.speedSlope, fruit.speedIntercept)),
          ResourceFlipField(loc.groupStrengthen,
              _formula(fruit.groupGainSlope, fruit.groupGainIntercept)),
          ResourceFlipField(
              loc.energyConsume, fruit.energyConsume?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _front(BuildContext context, FruitListView fruit, String name,
      AppLocalizations loc, VoidCallback onFlip) {
    final types = _typeMap(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context, fruit),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.primaryLabel)),
                ),
                if (fruit.fruitType != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: OnepieceTag.getFruitTag(
                        fruit.fruitType!, types[fruit.fruitType] ?? ''),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                if (fruit.imageUri?.isNotEmpty == true)
                  ImageLazyLoader(
                    key: ValueKey(fruit.imageUri),
                    uriProvider: () => fruit.imageUri!,
                    width: 44,
                    borderWidth: 0,
                    borderRadios: 9,
                    lazy: true,
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: OnepieceColors.surface,
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.spa_outlined,
                        size: 21, color: OnepieceColors.secondaryLabel),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.fruitHolders,
                          style: const TextStyle(
                              fontSize: 10,
                              color: OnepieceColors.secondaryLabel)),
                      const SizedBox(height: 4),
                      if (fruit.characters.isEmpty)
                        Text(loc.resourceNoHolders,
                            style: OnepieceFonts.smallContentStyle
                                .copyWith(fontSize: 11))
                      else
                        SizedBox(
                          height: 29,
                          child: _holderAvatars(context, fruit.characters),
                        ),
                    ],
                  ),
                ),
              ]),
              const Spacer(),
              const Divider(height: 10, color: OnepieceColors.separator),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onFlip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 31),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  icon: const Icon(Icons.flip_to_back_outlined, size: 16),
                  label: Text(loc.detailInformation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _holderAvatars(
      BuildContext context, List<CharacterInFruitView> characters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final character in characters)
            InkWell(
              onTap: () => context.goNamed('characterDetails',
                  extra: character.id,
                  pathParameters: {
                    'name': I18nHelper.getDisplayNameFromI18n(character.name)
                  }),
              child: Tooltip(
                message: I18nHelper.getDisplayNameFromI18n(character.name),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ImageLazyLoader(
                    uriProvider: () => character.imageUri ?? '',
                    width: 26,
                    borderWidth: 1,
                    borderRadios: 26,
                    lazy: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formula(double? slope, int? intercept) {
    if (slope == null || intercept == null) return '—';
    final factor = slope
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    if (intercept == 0) return '$factor×';
    final sign = intercept < 0 ? '−' : '+';
    return '$factor× $sign ${intercept.abs()}';
  }
}
