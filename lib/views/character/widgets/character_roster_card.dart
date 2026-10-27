import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

  Widget _avatar({required bool lazy, double size = 40}) {
    final uri = character.imageUri;
    if (uri == null || uri.isEmpty) {
      return Container(
        key: ValueKey('character-avatar-${character.id}'),
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: OnepieceColors.surface, shape: BoxShape.circle),
        child: Icon(Icons.person_outline,
            size: size * 0.55, color: OnepieceColors.secondaryLabel),
      );
    }
    return ImageLazyLoader(
      key: ValueKey('character-avatar-${character.id}'),
      uriProvider: () => uri,
      width: size,
      borderWidth: 0,
      borderRadios: size,
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
    final bounty = character.bounty == null
        ? '—'
        : NumberFormat.decimalPattern().format(character.bounty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Hero(
              tag: 'character-roster-${character.id}',
              child: _avatar(lazy: true, size: 44),
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
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Expanded(
                child: _frontMetric(
                  loc.combatPower,
                  NumberFormat.decimalPattern().format(character.score),
                  const TextStyle(
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: OnepieceColors.primaryLabel),
                ),
              ),
              const SizedBox(
                height: 39,
                child: VerticalDivider(
                    width: 15, thickness: 1, color: OnepieceColors.separator),
              ),
              Expanded(
                child: _frontMetric(loc.bounty, bounty,
                    OnepieceFonts.bountyStyle.copyWith(fontSize: 17)),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 18, runSpacing: 4, children: [
            _frontFact(loc.characterEnergy, '${character.energy}'),
            _frontFact(loc.fruitLimit, '${character.maximumFruitCount}'),
          ]),
          const Spacer(),
          const Divider(height: 1, color: OnepieceColors.separator),
          const SizedBox(height: 5),
          Text(loc.hakis,
              style: const TextStyle(
                  fontSize: 11, color: OnepieceColors.secondaryLabel)),
          const SizedBox(height: 4),
          _hakis.isEmpty
              ? const Text('—',
                  style: TextStyle(
                      fontSize: 12, color: OnepieceColors.secondaryLabel))
              : Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    for (final haki in _hakis)
                      OnepieceTag.getHakiTag(haki, hakiMap[haki] ?? ''),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _frontMetric(String label, String value, TextStyle valueStyle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 11, color: OnepieceColors.secondaryLabel)),
      const SizedBox(height: 3),
      Tooltip(
        message: '$label $value',
        child: SizedBox(
          width: double.infinity,
          height: 22,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, softWrap: false, style: valueStyle),
          ),
        ),
      ),
    ]);
  }

  Widget _frontFact(String label, String value) => Text.rich(TextSpan(
        style: const TextStyle(fontSize: 11),
        children: [
          TextSpan(
              text: '$label  ',
              style: const TextStyle(color: OnepieceColors.secondaryLabel)),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: OnepieceColors.primaryLabel)),
        ],
      ));

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
              child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${loc.bounty}  ',
                        style: const TextStyle(
                            color: OnepieceColors.secondaryLabel)),
                    TextSpan(
                        text: character.bounty == null
                            ? '—'
                            : NumberFormat.decimalPattern()
                                .format(character.bounty),
                        style:
                            OnepieceFonts.bountyStyle.copyWith(fontSize: 11)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
            ),
            if (_hakis.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(loc.hakis,
                  style: const TextStyle(
                      fontSize: 10, color: OnepieceColors.secondaryLabel)),
              const SizedBox(width: 4),
            ],
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
