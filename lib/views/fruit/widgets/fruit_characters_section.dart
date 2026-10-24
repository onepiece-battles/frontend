import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';

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
                            child: Text(I18nHelper.getDisplayNameFromI18n(c.name),
                                style: OnepieceFonts.contentStyle)),
                      ])),
                ),
              )),
        ]));
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    final wakeUpToDisplayValue = <bool, String>{
      true: AppLocalizations.of(context)!.wakeUp,
      false: AppLocalizations.of(context)!.sleep
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.owner,
          style: OnepieceFonts.headerStyle,
        ),
        if (characters.isEmpty)
          Text(
            AppLocalizations.of(context)!.currentlyNone,
            style: OnepieceFonts.fancyBlueHintFont,
          ),
        const SizedBox(
          height: 30,
        ),
        SizedBox(
          width: 600,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: characters.length,
            itemBuilder: (context, index) {
              var character = characters[index];
              return Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: ExpansionTile(
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    expandedAlignment: Alignment.centerLeft,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                              child: InkWell(
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  context.goNamed('characterDetails',
                                      extra: character.id,
                                      pathParameters: {
                                        'name':
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name)
                                      });
                                },
                                child: ImageLazyLoader(
                                    key: UniqueKey(),
                                    uriProvider: () => character.imageUri!,
                                    width: 40,
                                    borderWidth: 1.5,
                                    borderRadios: 40),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(I18nHelper.getDisplayNameFromI18n(
                                character.name)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getWakeUpTag(
                            character.wakeUp!,
                            wakeUpToDisplayValue[character.wakeUp!]!,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statRow(
                              'images/character_digits_icon/attack.svg',
                              21,
                              character.baseAttack,
                              character.attack),
                          const SizedBox(height: 10),
                          _statRow(
                              'images/character_digits_icon/defense.svg',
                              22,
                              character.baseDefense,
                              character.defense),
                          const SizedBox(height: 10),
                          _statRow(
                              'images/character_digits_icon/intelligence.svg',
                              22,
                              character.baseIntelligence,
                              character.intelligence),
                          const SizedBox(height: 10),
                          _statRow(
                              'images/character_digits_icon/speed.svg',
                              22,
                              character.baseSpeed,
                              character.speed),
                          const SizedBox(height: 10),
                          _statRow(
                              'images/character_digits_icon/blood.svg',
                              22,
                              character.baseBlood,
                              character.blood),
                          const SizedBox(height: 10),
                          _statRow(
                              'images/character_digits_icon/group_gain.svg',
                              20,
                              character.baseGroupGain,
                              character.groupGain),
                          const SizedBox(height: 10),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statRow(String icon, double iconSize, Object? base, Object? real) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ImageHelper.getTextFormFieldIcon(icon, true, iconSize),
        const SizedBox(width: 10),
        SizedBox(
            width: 80,
            child: Text("$base", style: OnepieceFonts.boldFancyBlueHintFont)),
        const Padding(
          padding: EdgeInsets.only(right: 50.0),
          child: Icon(Icons.arrow_right_alt_outlined),
        ),
        SizedBox(
            width: 80,
            child: Text("$real", style: OnepieceFonts.boldFancyBlueHintFont)),
      ],
    );
  }
}
