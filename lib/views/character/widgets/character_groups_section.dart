import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// The "groups" section of the character detail screen: the groups a character
/// belongs to. Compact card list on mobile, a tile list on desktop. Display
/// only — no local state.
class CharacterGroupsSection extends StatelessWidget {
  final List<GroupForCharacterView> groups;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterGroupsSection({
    super.key,
    required this.groups,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  Map<GroupCategory, String> _categoryMap(BuildContext context) => {
        GroupCategory.marine: AppLocalizations.of(context)!.marine,
        GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
        GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
        GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
        GroupCategory.group: AppLocalizations.of(context)!.group,
        GroupCategory.other: AppLocalizations.of(context)!.otherType,
        GroupCategory.revolutionArmy:
            AppLocalizations.of(context)!.revolutionaryArmy,
      };

  Map<GroupPosition, String> _positionMap(BuildContext context) => {
        GroupPosition.member: AppLocalizations.of(context)!.member,
        GroupPosition.captain: AppLocalizations.of(context)!.caption,
        GroupPosition.combatant: AppLocalizations.of(context)!.combatant,
        GroupPosition.cook: AppLocalizations.of(context)!.cook,
        GroupPosition.doctor: AppLocalizations.of(context)!.doctor,
        GroupPosition.firstMate: AppLocalizations.of(context)!.firstMate,
        GroupPosition.helmsman: AppLocalizations.of(context)!.helmsman,
        GroupPosition.intern: AppLocalizations.of(context)!.intern,
        GroupPosition.musician: AppLocalizations.of(context)!.musician,
        GroupPosition.navigator: AppLocalizations.of(context)!.navigator,
        GroupPosition.scholar: AppLocalizations.of(context)!.scholar,
        GroupPosition.shipwright: AppLocalizations.of(context)!.shipwright,
      };

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final catMap = _categoryMap(context);
    final posMap = _positionMap(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.group,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...groups.map((g) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.goNamed('groupDetails',
                          extra: g.groupId,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(g.name!)
                          }),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(children: [
                            ImageLazyLoader(
                                key: ValueKey(g.imageUri),
                                uriProvider: () => g.imageUri!,
                                width: 36,
                                borderWidth: 1.5,
                                borderRadios: 8),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                            I18nHelper.getDisplayNameFromI18n(
                                                g.name!),
                                            style: OnepieceFonts.contentStyle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    OnepieceTag.getGroupTag(
                                        g.category!, catMap[g.category!]!)
                                  ]),
                                  Text(posMap[g.position!]!,
                                      style: OnepieceFonts.smallContentStyle),
                                ])),
                          ])),
                    ),
                  )),
            ],
          ])),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  AppLocalizations.of(context)!.group,
                  style: OnepieceFonts.headerStyle,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
          child: _getGroupList(context),
        ),
      ],
    );
  }

  Widget _getGroupList(BuildContext context) {
    final catMap = _categoryMap(context);
    final posMap = _positionMap(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: dividerWidth - sideWidth - 16,
        decoration: const BoxDecoration(
          color: OnepieceColors.menuBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            var currentGroup = groups[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: ListTile(
                  minLeadingWidth: 10,
                  contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  selectedTileColor: OnepieceColors.liteFancyBlue,
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: currentGroup.groupId,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(
                              currentGroup.name!)
                        });
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: <Widget>[
                            Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ImageLazyLoader(
                                    key: UniqueKey(),
                                    uriProvider: () => currentGroup.imageUri!,
                                    width: 50,
                                    borderWidth: 2,
                                    borderRadios: 10)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  I18nHelper.getDisplayNameFromI18n(
                                      currentGroup.name!),
                                  style: OnepieceFonts.deepBlackHintFont,
                                ),
                                Text(
                                  posMap[currentGroup.position!]!,
                                  style: OnepieceFonts.boldLiteFancySmallFont,
                                )
                              ],
                            ),
                          ],
                        ),
                        OnepieceTag.getGroupTag(currentGroup.category!,
                            catMap[currentGroup.category!]!)
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
