import 'package:flutter/material.dart';
import '../../../components/resource_detail_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// The "characters" (owners) section of the fruit detail screen: the characters
/// who have eaten this fruit. Display only — a compact card list on mobile, and
/// an expandable base→real stat breakdown per character on desktop.
class FruitCharactersSection extends StatelessWidget {
  final List<CharacterInFruitView> characters;
  final bool isNarrow;

  const FruitCharactersSection({
    super.key,
    required this.characters,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    if (characters.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context)!.character,
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          ...characters.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.goNamed('characterDetails',
                      extra: c.id,
                      pathParameters: {
                        'name': I18nHelper.getDisplayNameFromI18n(c.name)
                      }),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(children: [
                        ImageLazyLoader(
                            key: ValueKey(c.imageUri),
                            uriProvider: () => c.imageUri!,
                            width: 36,
                            borderWidth: 1.5,
                            borderRadios: 36),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                I18nHelper.getDisplayNameFromI18n(c.name),
                                style: OnepieceFonts.contentStyle)),
                      ])),
                ),
              )),
        ]));
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DetailSection(
        title: loc.owner,
        child: characters.isEmpty
            ? Text(loc.currentlyNone, style: OnepieceFonts.smallContentStyle)
            : Column(
                children: characters
                    .map((character) => ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          leading: ImageLazyLoader(
                              uriProvider: () => character.imageUri ?? '',
                              width: 40,
                              borderWidth: 0,
                              borderRadios: 40),
                          title: Text(
                              I18nHelper.getDisplayNameFromI18n(character.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => context.goNamed('characterDetails',
                              extra: character.id,
                              pathParameters: {
                                'name': I18nHelper.getDisplayNameFromI18n(
                                    character.name)
                              }),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            OnepieceTag.getWakeUpTag(
                                character.wakeUp ?? false,
                                character.wakeUp == true
                                    ? loc.wakeUp
                                    : loc.sleep),
                            const SizedBox(width: 12),
                            TextButton(
                                onPressed: () => showResourceDetails(
                                    context,
                                    I18nHelper.getDisplayNameFromI18n(
                                        character.name),
                                    DetailFieldGrid(fields: [
                                      DetailValue(loc.characterAttack,
                                          '${character.baseAttack} → ${character.attack}'),
                                      DetailValue(loc.characterDefense,
                                          '${character.baseDefense} → ${character.defense}'),
                                      DetailValue(loc.characterBlood,
                                          '${character.baseBlood} → ${character.blood}'),
                                      DetailValue(loc.characterSpeed,
                                          '${character.baseSpeed} → ${character.speed}'),
                                      DetailValue(loc.characterIntelligence,
                                          '${character.baseIntelligence} → ${character.intelligence}'),
                                      DetailValue(loc.groupGain,
                                          '${character.baseGroupGain} → ${character.groupGain}'),
                                    ])),
                                child: Text(loc.detailInformation)),
                          ]),
                        ))
                    .toList()));
  }
}
