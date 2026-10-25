import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/button_style.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/join_group.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../../../utils/nested_scroll_helper.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../group_detail_controller.dart';

/// The "members" panel of the group detail screen: the father-group trail, the
/// member tree (groups expand to lazily-loaded child groups / characters) or a
/// flat character list, and an inline base->real combat-stat breakdown per
/// character. Owns the tree node state and the per-character combat cache;
/// lazy-loads children and stats through [GroupDetailController].
class GroupMembersPanel extends StatefulWidget {
  final GroupFullView groupFullView;
  final GroupDetailController controller;
  final ScrollController pageScrollController;
  final bool editButtonVisible;

  const GroupMembersPanel({
    super.key,
    required this.groupFullView,
    required this.controller,
    required this.pageScrollController,
    required this.editButtonVisible,
  });

  @override
  State<GroupMembersPanel> createState() => _GroupMembersPanelState();
}

class _GroupMembersPanelState extends State<GroupMembersPanel> {
  late GroupNode root;
  final Map<String, CharacterFullView> _characterCombatCache = {};
  final Set<String> _loadingCharacterCombatIds = {};

  GroupFullView get groupFullView => widget.groupFullView;
  GroupDetailController get _controller => widget.controller;
  ScrollController get _pageScrollController => widget.pageScrollController;
  bool get _editButtonVisible => widget.editButtonVisible;
  List<CharacterInGroupView> get characters => widget.groupFullView.characters;

  @override
  void initState() {
    super.initState();
    _buildRoot();
  }

  @override
  void didUpdateWidget(covariant GroupMembersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupFullView.id != widget.groupFullView.id) {
      _buildRoot();
    }
  }

  void _buildRoot() {
    root = GroupNode(
        groupFullView.subGroups.map((e) => GroupNode([], false, e)).toList(),
        true,
        Group(
            id: groupFullView.id,
            fatherGroupId: groupFullView.fatherGroupId,
            creationRecordId: groupFullView.creationRecordId,
            modificationRecordId: groupFullView.modificationRecordId,
            groupCategory: groupFullView.groupCategory,
            name: groupFullView.name,
            imageUri: groupFullView.imageUri));
  }

  @override
  Widget build(BuildContext context) => _getMembersPanel(context);

  Widget _getMembersPanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final panelWidth = availableWidth;
        final contentWidth = isNarrow
            ? (panelWidth - 32 > 280 ? panelWidth - 32 : 280.0)
            : panelWidth - 48;

        return SizedBox(
          width: panelWidth,
          child: Card(
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: OnepieceColors.separator.withValues(alpha: 0.7),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isNarrow ? 12 : 24, 24, isNarrow ? 12 : 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isNarrow) Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: OnepieceColors.liteFancyGreen
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_tree_outlined,
                            size: 20, color: OnepieceColors.fancyGreen),
                      ),
                      if (isNarrow) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          groupFullView.groupCategory == GroupCategory.group
                              ? AppLocalizations.of(context)!.groupStructure
                              : AppLocalizations.of(context)!.groupMember,
                          style: OnepieceFonts.headerStyle.copyWith(
                            fontSize: isNarrow ? 18 : 19,
                            fontWeight: FontWeight.w600,
                            color: OnepieceColors.primaryLabel,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_editButtonVisible)
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () => _showDialog(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: OnepieceColors.fancyBlue
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: OnepieceColors.fancyBlue
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Icon(Icons.add,
                                size: 20, color: OnepieceColors.fancyBlue),
                          ),
                        ),
                    ],
                  ),
                  if (groupFullView.fatherGroups.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    getFatherList(context),
                  ],
                  if (groupFullView.characters.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: OnepieceColors.menuHoverColor
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.thisGroup,
                        style: OnepieceFonts.navigationTopBarStyleClickable
                            .copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (groupFullView.characters.isEmpty && groupFullView.subGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(AppLocalizations.of(context)!.empty,
                        style: const TextStyle(color: OnepieceColors.secondaryLabel, fontSize: 14)),
                    ),
                  NestedHorizontalScrollView(
                    verticalParentController: _pageScrollController,
                    child: SizedBox(
                      width: contentWidth,
                      child: root.group.groupCategory == GroupCategory.group
                          ? buildTreeNode(root, false, 1)
                          : buildCharacterList(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getFatherList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.fatherGroups,
          style: OnepieceFonts.navigationTopBarStyleClickable,
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: groupFullView.fatherGroups.reversed.toList().map((e) {
            return Row(
              children: [
                ElevatedButton(
                    style: OnepieceButtonStyle.getFatherGroupButtonStyle(),
                    onPressed: () {
                      context.goNamed('groupDetails',
                          extra: e.id,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(e.name!)
                          });
                    },
                    child: Row(
                      children: [
                        ImageLazyLoader(
                            uriProvider: () => e.imageUri!,
                            width: 40,
                            borderWidth: 1.5,
                            borderRadios: 3),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            I18nHelper.getDisplayNameFromI18n(e.name!),
                          ),
                        )
                      ],
                    )),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                )
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  void _showDialog(BuildContext context) {
    showCupertinoModalPopup(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      context: context,
      builder: ((context) {
        return Dialog(
          backgroundColor: Colors.white,
          alignment: Alignment.topCenter,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: JoinGroup(fatherGroup: groupFullView),
        );
      }),
    );
  }

  Widget buildCharacterList(BuildContext context) {
    return SizedBox(
      width: 600,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: characters.length,
        itemBuilder: (context, index) {
          var character = characters[index];
          return _buildCharacterExpansionCard(
              character: character, isTreeLeaf: false);
        },
      ),
    );
  }

  void handleExpansionChanged(
      bool isExpanded, GroupNode node, StateSetter nodeState) {
    if (isExpanded && !node.childrenFetched) {
      // Simulate fetching children from the backend
      List<TreeNode> fetchedChildren = [];
      if (node.group.groupCategory == GroupCategory.group) {
        _controller
            .listChildGroups(ListChildGroupsRequest(groupId: node.group.id))
            .then((value) {
          fetchedChildren = value!.childGroups.map((e) {
            return GroupNode([], false, e);
          }).toList();
          if (!mounted) return;
          nodeState(() {
            node.children = fetchedChildren;
            node.childrenFetched = true;
          });
        });
      } else {
        _controller
            .listChildCharacters(
                ListChildCharactersRequest(groupId: node.group.id))
            .then((value) {
          fetchedChildren = value!.childCharacters.map((e) {
            return CharacterNode([], true, e);
          }).toList();
          if (!mounted) return;
          nodeState(() {
            node.children = fetchedChildren;
            node.childrenFetched = true;
          });
        });
      }
    }
  }

  Widget buildTreeNode(TreeNode node, bool isChildCharacter, int level) {
    if (!isChildCharacter) {
      GroupNode actualNode = node as GroupNode;
      return StatefulBuilder(
        builder: (context, nodeState) {
          return Container(
            margin: EdgeInsets.only(top: level == 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: level == 1
                  ? OnepieceColors.liteFancyBlue.withValues(alpha: 0.20)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: level == 1
                    ? OnepieceColors.fancyBlue.withValues(alpha: 0.18)
                    : OnepieceColors.menuHoverColor.withValues(alpha: 0.55),
              ),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                expandedAlignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                leading: Icon(
                  actualNode.group.groupCategory == GroupCategory.group
                      ? Icons.account_tree_outlined
                      : Icons.groups_2_outlined,
                  size: 18,
                  color: OnepieceColors.fancyBlue,
                ),
                title: _buildTreeTitle(
                  imageUri: node.group.imageUri!,
                  title:
                      I18nHelper.getDisplayNameFromI18n(actualNode.group.name!),
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: node.group.id,
                        pathParameters: {
                          'name':
                              I18nHelper.getDisplayNameFromI18n(node.group.name)
                        });
                  },
                ),
                onExpansionChanged: (isExpanded) =>
                    handleExpansionChanged(isExpanded, actualNode, nodeState),
                children: actualNode.children
                    .map((child) => buildTreeNode(
                        child,
                        actualNode.group.groupCategory != GroupCategory.group,
                        level + 1))
                    .toList(),
              ),
            ),
          );
        },
      );
    } else {
      CharacterNode actualNode = node as CharacterNode;
      return _buildCharacterExpansionCard(
          character: actualNode.characterInGroupView, isTreeLeaf: true);
    }
  }

  Widget _buildCharacterExpansionCard({
    required CharacterInGroupView character,
    required bool isTreeLeaf,
  }) {
    return StatefulBuilder(
      builder: (context, cardState) {
        return Container(
          margin: EdgeInsets.only(top: isTreeLeaf ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: OnepieceColors.menuHoverColor.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isTreeLeaf ? 0.02 : 0.04),
                blurRadius: isTreeLeaf ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              expandedAlignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.person_outline,
                  size: 18, color: OnepieceColors.fancyGreen),
              title: _buildTreeTitle(
                imageUri: character.imageUri!,
                title: I18nHelper.getDisplayNameFromI18n(character.name!),
                onTap: () {
                  context.goNamed('characterDetails',
                      extra: character.id,
                      pathParameters: {
                        'name':
                            I18nHelper.getDisplayNameFromI18n(character.name)
                      });
                },
              ),
              onExpansionChanged: (isExpanded) {
                if (isExpanded) {
                  _loadCharacterCombatStats(character, cardState);
                }
              },
              children: [_buildCharacterCombatStats(character)],
            ),
          ),
        );
      },
    );
  }

  void _loadCharacterCombatStats(
      CharacterInGroupView character, StateSetter cardState) {
    final characterId = _getCharacterLookupId(character);
    if (characterId == null ||
        _characterCombatCache.containsKey(characterId) ||
        _loadingCharacterCombatIds.contains(characterId)) {
      return;
    }
    cardState(() {
      _loadingCharacterCombatIds.add(characterId);
    });
    _controller
        .getCharacter(GetCharacterFullViewRequest(characterId: characterId))
        .then((value) {
      if (!mounted) return;
      cardState(() {
        _loadingCharacterCombatIds.remove(characterId);
        if (value != null) {
          _characterCombatCache[characterId] = value;
        }
      });
    }).catchError((_) {
      if (!mounted) return;
      cardState(() {
        _loadingCharacterCombatIds.remove(characterId);
      });
    });
  }

  String? _getCharacterLookupId(CharacterInGroupView character) {
    return character.characterId ?? character.id;
  }

  Widget _buildCharacterCombatStats(CharacterInGroupView character) {
    final characterId = _getCharacterLookupId(character);
    final fullView =
        characterId == null ? null : _characterCombatCache[characterId];
    if (characterId != null &&
        _loadingCharacterCombatIds.contains(characterId)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: OnepieceColors.liteFancyGreen.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const LinearProgressIndicator(minHeight: 3),
      );
    }
    if (fullView == null) {
      return const SizedBox.shrink();
    }

    final stats = <_GroupCharacterStat>[
      _GroupCharacterStat(AppLocalizations.of(context)!.characterAttack,
          fullView.attack.toString(),
          icon: 'images/character_digits_icon/attack.svg'),
      _GroupCharacterStat(AppLocalizations.of(context)!.characterDefense,
          fullView.defense.toString(),
          icon: 'images/character_digits_icon/defense.svg'),
      _GroupCharacterStat(AppLocalizations.of(context)!.characterIntelligence,
          fullView.intelligence.toString(),
          icon: 'images/character_digits_icon/intelligence.svg'),
      _GroupCharacterStat(AppLocalizations.of(context)!.characterBlood,
          fullView.blood.toString(),
          icon: 'images/character_digits_icon/blood.svg'),
      _GroupCharacterStat(AppLocalizations.of(context)!.characterSpeed,
          fullView.speed.toString(),
          icon: 'images/character_digits_icon/speed.svg'),
      _GroupCharacterStat(AppLocalizations.of(context)!.groupGain,
          fullView.groupGain.toString(),
          icon: 'images/character_digits_icon/group_gain.svg'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyGreen.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: stats
            .map((stat) => _buildCharacterStatChip(stat))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildCharacterStatChip(_GroupCharacterStat stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat.icon != null) ...[
            ImageHelper.getTextFormFieldIcon(stat.icon!, false, 15),
            const SizedBox(width: 5),
          ],
          Text(stat.label, style: OnepieceFonts.smallContentStyle),
          const SizedBox(width: 6),
          Text(stat.value, style: OnepieceFonts.boldFancySmallFont),
        ],
      ),
    );
  }

  Widget _buildTreeTitle({
    required String imageUri,
    required String title,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: onTap,
          child: ImageLazyLoader(
              uriProvider: () => imageUri,
              width: 38,
              borderWidth: 1.4,
              borderRadios: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnepieceFonts.contentStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class TreeNode {
  List<TreeNode> children;
  bool childrenFetched;

  TreeNode(this.children, this.childrenFetched);
}

class GroupNode extends TreeNode {
  Group group;

  GroupNode(super.children, super.childrenFetched, this.group);

  @override
  String toString() {
    return group.toString();
  }
}

class CharacterNode extends TreeNode {
  CharacterInGroupView characterInGroupView;

  CharacterNode(
      super.children, super.childrenFetched, this.characterInGroupView);
}

class _GroupCharacterStat {
  final String label;
  final String value;
  final String? icon;

  const _GroupCharacterStat(this.label, this.value, {this.icon});
}
