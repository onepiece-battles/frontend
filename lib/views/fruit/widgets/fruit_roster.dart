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

/// Two-sided fruit cards for both responsive list layouts. The front is the
/// brief glance; the back keeps the front (shrunk) and adds the full strengthen
/// numbers. A plain tap opens the detail page; the flip button only turns the
/// card. Flipped state is owned by the parent so it survives scrolling.
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
          key: ValueKey('fruit-card-shell-${fruit.id}'),
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
      minCardWidth: 315,
      maxColumns: 8,
      gap: 10,
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
    return ResourceFlipCard(
      key: ValueKey('fruit-card-${fruit.id}'),
      baseHeight: 225,
      flipped: expandedRowIds.contains(fruit.id),
      front: _face(context, fruit, _frontContent(context, fruit, name, loc),
          Icons.flip_to_back_outlined, loc.detailInformation),
      back: _face(context, fruit, _backContent(context, fruit, name, loc),
          Icons.flip_to_front_outlined, loc.flipCardBack),
    );
  }

  Widget _face(BuildContext context, FruitListView fruit, Widget content,
      IconData flipIcon, String tooltip) {
    return Stack(children: [
      Positioned.fill(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context, fruit),
            child: content,
          ),
        ),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: IconButton(
          tooltip: tooltip,
          onPressed: () => onToggleExpand(fruit.id!),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(flipIcon, size: 19, color: OnepieceColors.secondaryLabel),
        ),
      ),
    ]);
  }

  Widget _fruitImage(FruitListView fruit, double size, {bool eager = false}) {
    if (fruit.imageUri?.isNotEmpty == true) {
      return ImageLazyLoader(
        key: ValueKey('fruit-avatar-${fruit.id}'),
        uriProvider: () => fruit.imageUri!,
        width: size,
        borderWidth: 0,
        borderRadios: size * 0.2,
        lazy: !eager,
      );
    }
    return Container(
      key: ValueKey('fruit-avatar-${fruit.id}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(size * 0.2)),
      child: Icon(Icons.spa_outlined,
          size: size * 0.46, color: OnepieceColors.secondaryLabel),
    );
  }

  Widget _typeTag(BuildContext context, FruitListView fruit) {
    if (fruit.fruitType == null) return const SizedBox.shrink();
    return OnepieceTag.getFruitTag(
        fruit.fruitType!, _typeMap(context)[fruit.fruitType] ?? '');
  }

  // ── Front: brief glance ──────────────────────────────────────────────
  Widget _frontContent(BuildContext context, FruitListView fruit, String name,
      AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
          ),
          const SizedBox(width: 36),
        ]),
        if (fruit.fruitType != null) ...[
          const SizedBox(height: 5),
          _typeTag(context, fruit),
        ],
        Expanded(
          child: Row(children: [
            _fruitImage(fruit, 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.fruitHolders,
                      style: const TextStyle(
                          fontSize: 10, color: OnepieceColors.secondaryLabel)),
                  const SizedBox(height: 4),
                  if (fruit.characters.isEmpty)
                    Text(loc.resourceNoHolders,
                        style: OnepieceFonts.smallContentStyle
                            .copyWith(fontSize: 11))
                  else
                    SizedBox(
                        height: 22,
                        child: _holderAvatars(context, fruit.characters)),
                ],
              ),
            ),
          ]),
        ),
        const Divider(height: 10, color: OnepieceColors.separator),
        Row(children: [
          Text(loc.energyConsume,
              style: const TextStyle(
                  fontSize: 11, color: OnepieceColors.secondaryLabel)),
          const Spacer(),
          Text(fruit.energyConsume?.toString() ?? '—',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: OnepieceColors.primaryLabel)),
        ]),
      ]),
    );
  }

  // ── Back: the whole front, shrunk, plus the full strengthen numbers ───
  Widget _backContent(BuildContext context, FruitListView fruit, String name,
      AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _fruitImage(fruit, 40, eager: true),
            const SizedBox(width: 7),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel)),
            ),
            const SizedBox(width: 6),
            Flexible(child: _typeTag(context, fruit)),
            const SizedBox(width: 36),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ResourceNumberGrid(
                columns: 1,
                rowGap: 5,
                fontSize: 12,
                items: [
                  ResourceNumber(loc.characterAttack,
                      _formula(fruit.attackSlope, fruit.attackIntercept)),
                  ResourceNumber(loc.characterDefense,
                      _formula(fruit.defenseSlope, fruit.defenseIntercept)),
                  ResourceNumber(loc.characterBlood,
                      _formula(fruit.bloodSlope, fruit.bloodIntercept)),
                  ResourceNumber(
                      loc.characterIntelligence,
                      _formula(fruit.intelligenceSlope,
                          fruit.intelligenceIntercept)),
                  ResourceNumber(loc.characterSpeed,
                      _formula(fruit.speedSlope, fruit.speedIntercept)),
                  ResourceNumber(loc.groupGain,
                      _formula(fruit.groupGainSlope, fruit.groupGainIntercept)),
                  ResourceNumber(loc.energyConsume,
                      fruit.energyConsume?.toString() ?? '—'),
                ],
              ),
            ),
          ),
        ],
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
                    width: 22,
                    borderWidth: 1,
                    borderRadios: 22,
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
