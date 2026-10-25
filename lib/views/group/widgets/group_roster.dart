import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// The group list body: a card list on mobile, a spotlight grid on desktop.
/// Each card shows the group's avatar, name, creator, category and a horizontal
/// strip of its members (characters, or sub-groups for a "group of groups").
class GroupRoster extends StatelessWidget {
  final List<GroupListView> groups;
  final ScrollController controller;
  final bool isNarrow;

  const GroupRoster({
    super.key,
    required this.groups,
    required this.controller,
    required this.isNarrow,
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

  // ── Mobile: card-based group list ─────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final categoryMap = _categoryMap(context);

    if (groups.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final isEven = index.isEven;

        return Card(
          elevation: 0,
          color: isEven ? OnepieceColors.surface : Colors.white,
          margin: const EdgeInsets.only(bottom: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('groupDetails',
                extra: group.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(group.name)
                }),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: image + name + category
                  Row(
                    children: [
                      RepaintBoundary(
                        child: ImageLazyLoader(
                          key: ValueKey(group.imageUri),
                          uriProvider: () => group.imageUri!,
                          width: 32,
                          borderWidth: 1.5,
                          borderRadios: 5,
                          lazy: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              I18nHelper.getDisplayNameFromI18n(group.name),
                              style: OnepieceFonts.headerStyle
                                  .copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.creationRecord?.nickname ?? '',
                              style: OnepieceFonts.smallContentStyle
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              OnepieceColors.fancyBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryMap[group.groupCategory] ?? '',
                          style: OnepieceFonts.smallContentStyle.copyWith(
                              color: OnepieceColors.fancyBlue, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  // Members row
                  if (group.characterInGroup.isNotEmpty ||
                      group.subGroups.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: group.groupCategory == GroupCategory.group
                          ? _createGroupList(context, group.subGroups)
                          : _createCharacterList(
                              context, group.characterInGroup),
                    ),
                  ],
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
    if (groups.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }
    final categoryMap = _categoryMap(context);

    return DesktopSpotlightGrid<GroupListView>(
      items: groups,
      idOf: (group) => group.id,
      controller: controller,
      minCardWidth: 280,
      maxColumns: 6,
      gap: 10,
      cardBuilder: (context, group) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.goNamed('groupDetails',
              extra: group.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(group.name)
              }),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ImageLazyLoader(
                    key: ValueKey(group.imageUri),
                    uriProvider: () => group.imageUri!,
                    width: 36,
                    borderWidth: 0,
                    lazy: true,
                    borderRadios: 10,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          I18nHelper.getDisplayNameFromI18n(group.name),
                          style: OnepieceFonts.contentStyleBold.copyWith(
                              color: OnepieceColors.primaryLabel, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(group.creationRecord?.nickname ?? '',
                            style: OnepieceFonts.smallContentStyle),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: OnepieceColors.fancyBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(categoryMap[group.groupCategory] ?? '',
                        style: OnepieceFonts.boldFancySmallFont),
                  ),
                ]),
                if (group.subGroups.isNotEmpty ||
                    group.characterInGroup.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: group.groupCategory == GroupCategory.group
                        ? _createGroupList(context, group.subGroups)
                        : _createCharacterList(context, group.characterInGroup),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createCharacterList(
      BuildContext context, List<CharacterInGroupLite> characters) {
    if (characters.isEmpty) {
      return const Text("");
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: characters.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final character = characters[index];
        return InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () {
            context.goNamed('characterDetails',
                extra: character.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(character.name!)
                });
          },
          child: Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(character.name),
            preferBelow: false,
            showDuration: const Duration(seconds: 1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
              child: RepaintBoundary(
                child: ImageLazyLoader(
                    key: ValueKey(character.imageUri),
                    uriProvider: () => character.imageUri!,
                    width: 24,
                    borderWidth: 1.5,
                    borderRadios: 40,
                    lazy: true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createGroupList(BuildContext context, List<Group> groups) {
    if (groups.isEmpty) {
      return const Text("");
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: groups.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final group = groups[index];
        return InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () {
            context.goNamed('groupDetails', extra: group.id, pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(group.name!)
            });
          },
          child: Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(group.name),
            preferBelow: false,
            showDuration: const Duration(seconds: 1),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                child: RepaintBoundary(
                  child: ImageLazyLoader(
                      key: ValueKey(group.imageUri),
                      uriProvider: () => group.imageUri!,
                      width: 24,
                      borderWidth: 1.5,
                      borderRadios: 3,
                      lazy: true),
                )),
          ),
        );
      },
    );
  }
}
