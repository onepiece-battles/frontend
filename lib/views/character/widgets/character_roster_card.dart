import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../components/resource_flip_card.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

class CharacterRosterCard extends StatelessWidget {
  const CharacterRosterCard({
    super.key,
    required this.character,
    required this.battleStyleMap,
    required this.raceMap,
    required this.hakiMap,
    required this.flipped,
    required this.onFlip,
  });

  final CharacterListView character;
  final Map<BattleStyle, String> battleStyleMap;
  final Map<Race, String> raceMap;
  final Map<Haki, String> hakiMap;
  final bool flipped;
  final VoidCallback onFlip;

  void _open(BuildContext context) =>
      context.goNamed('characterDetails', extra: character.id, pathParameters: {
        'name': I18nHelper.getDisplayNameFromI18n(character.name)
      });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = I18nHelper.getDisplayNameFromI18n(character.name);
    return ResourceFlipCard(
      flipped: flipped,
      front: _front(context, loc, name),
      back: ResourceFlipDetail(
        title: name,
        onFlipBack: onFlip,
        onOpen: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResourceStatBars(bars: [
              ResourceStatBar(loc.characterAttack, '${character.attack}',
                  statFraction(character.attack, 10, 1500)),
              ResourceStatBar(loc.characterDefense, '${character.defense}',
                  statFraction(character.defense, 10, 1400)),
              ResourceStatBar(
                  loc.characterIntelligence,
                  '${character.intelligence}',
                  statFraction(character.intelligence, 70, 260)),
              ResourceStatBar(loc.characterBlood, '${character.blood}',
                  statFraction(character.blood, 100, 10000)),
              ResourceStatBar(loc.characterSpeed, '${character.speed}',
                  statFraction(character.speed, 10, 200)),
            ]),
            const Spacer(),
            ResourceMetaChips(chips: [
              ResourceMetaChip(loc.groupGain, '${character.groupGain}'),
              ResourceMetaChip(loc.fruitLimit, '${character.maximumFruitCount}'),
              ResourceMetaChip(loc.characterEnergy, '${character.energy}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _front(BuildContext context, AppLocalizations loc, String name) {
    final race = raceMap[character.race] ?? '';
    final battleStyle = battleStyleMap[character.battleStyle] ?? '';
    final hakis = character.hakis.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Hero(
                  tag: 'character-roster-${character.id}',
                  child: ImageLazyLoader(
                    key: ValueKey(character.imageUri),
                    uriProvider: () => character.imageUri ?? '',
                    width: 38,
                    borderWidth: 0,
                    borderRadios: 38,
                    lazy: true,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.primaryLabel)),
                      const SizedBox(height: 3),
                      Text('$race · $battleStyle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OnepieceFonts.smallContentStyle
                              .copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 17, color: OnepieceColors.secondaryLabel),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _summaryValue(loc.combatPower, '${character.score}'),
                const SizedBox(width: 18),
                Expanded(
                    child: _summaryValue(loc.bounty,
                        character.bounty == null ? '—' : '${character.bounty}',
                        valueStyle: OnepieceFonts.bountyStyle)),
              ]),
              const Spacer(),
              const Divider(height: 10, color: OnepieceColors.separator),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [
                      for (final haki in hakis)
                        OnepieceTag.getHakiTag(haki, hakiMap[haki] ?? ''),
                    ],
                  ),
                ),
                TextButton.icon(
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
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryValue(String label, String value, {TextStyle? valueStyle}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            maxLines: 1,
            style: const TextStyle(
                fontSize: 10, color: OnepieceColors.secondaryLabel)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
      ]);
}
