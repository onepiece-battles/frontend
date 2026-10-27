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

/// A compact two-sided character card. The front is the brief glance; the back
/// keeps everything the front shows (shrunk) and adds the full stat numbers.
/// A plain tap opens the detail page; the small flip button (a sibling above
/// the tap target) only turns the card.
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

  List<Haki> get _hakis => character.hakis.toList()
    ..sort((a, b) => a.toString().compareTo(b.toString()));

  Widget _avatar({required bool lazy}) {
    final uri = character.imageUri;
    if (uri == null || uri.isEmpty) {
      return Container(
        key: ValueKey('character-avatar-${character.id}'),
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: OnepieceColors.surface, shape: BoxShape.circle),
        child: const Icon(Icons.person_outline,
            size: 22, color: OnepieceColors.secondaryLabel),
      );
    }
    return ImageLazyLoader(
      key: ValueKey('character-avatar-${character.id}'),
      uriProvider: () => uri,
      width: 40,
      borderWidth: 0,
      borderRadios: 40,
      lazy: lazy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = I18nHelper.getDisplayNameFromI18n(character.name);
    return ResourceFlipCard(
      flipped: flipped,
      front: _face(context, _frontContent(context, loc, name),
          Icons.flip_to_back_outlined, loc.detailInformation),
      back: _face(context, _backContent(context, loc, name),
          Icons.flip_to_front_outlined, loc.flipCardBack),
    );
  }

  /// A card face: tappable content (opens the detail page) with the flip button
  /// layered above as a sibling, so a tap on it flips instead of navigating.
  Widget _face(
      BuildContext context, Widget content, IconData flipIcon, String tooltip) {
    return Stack(children: [
      Positioned.fill(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context),
            child: content,
          ),
        ),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onFlip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(flipIcon, size: 19, color: OnepieceColors.secondaryLabel),
        ),
      ),
    ]);
  }

  // ── Front: brief glance ──────────────────────────────────────────────
  Widget _frontContent(
      BuildContext context, AppLocalizations loc, String name) {
    final race = raceMap[character.race] ?? '';
    final battleStyle = battleStyleMap[character.battleStyle] ?? '';
    final subtitle = [race, battleStyle].where((e) => e.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Hero(
              tag: 'character-roster-${character.id}',
              child: _avatar(lazy: true),
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
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: OnepieceColors.secondaryLabel)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 36),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.combatPower,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: OnepieceColors.secondaryLabel)),
                  Text('${character.score}',
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: OnepieceColors.primaryLabel)),
                ],
              ),
            ),
            Text(character.bounty == null ? '—' : '${character.bounty}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnepieceFonts.bountyStyle.copyWith(fontSize: 15)),
          ]),
          if (_hakis.isNotEmpty)
            SizedBox(
              height: 22,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final haki in _hakis)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: OnepieceTag.getHakiTag(haki, hakiMap[haki] ?? ''),
                    ),
                ]),
              ),
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ── Back: the whole front, shrunk, plus the full stat numbers ─────────
  Widget _backContent(BuildContext context, AppLocalizations loc, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _avatar(lazy: false),
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
            Text('${character.score}',
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: OnepieceColors.primaryLabel)),
            const SizedBox(width: 36),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Flexible(
              child: Text(
                  character.bounty == null ? '—' : '${character.bounty}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57C00))),
            ),
            const SizedBox(width: 8),
            for (final haki in _hakis)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: hakiMap[haki] ?? '',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OnepieceTag.hakiToColor[haki],
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ResourceNumberGrid(rowGap: 10, fontSize: 13, items: [
                ResourceNumber(loc.characterAttack, '${character.attack}'),
                ResourceNumber(loc.characterSpeed, '${character.speed}'),
                ResourceNumber(loc.characterDefense, '${character.defense}'),
                ResourceNumber(loc.groupGain, '${character.groupGain}'),
                ResourceNumber(
                    loc.characterIntelligence, '${character.intelligence}'),
                ResourceNumber(
                    loc.fruitLimit, '${character.maximumFruitCount}'),
                ResourceNumber(loc.characterBlood, '${character.blood}'),
                ResourceNumber(loc.characterEnergy, '${character.energy}'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
