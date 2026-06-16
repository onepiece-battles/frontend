import 'dart:async';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:openapi/api.dart';
import 'package:get_it/get_it.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/character_dao.dart';
import '../repository/group_dao.dart';
import '../app_router.dart';
import '../utils/i18n_helper.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;
Timer? _timer;

class JoinGroup extends StatefulWidget {
  final GroupFullView fatherGroup;

  const JoinGroup({super.key, required this.fatherGroup});

  @override
  State<JoinGroup> createState() => _JoinGroupState();
}

class _JoinGroupState extends State<JoinGroup> {
  final ScrollController selectedController = ScrollController();
  final ScrollController selectableController = ScrollController();
  late Future myFuture;
  GroupFilter groupFilter = GroupFilter();
  CharacterFilter characterFilter = CharacterFilter();
  List<GroupListView> groups = [];
  List<GroupListView> selectedGroups = [];
  List<CharacterListView> characters =
      <CharacterListView>[].toList(growable: true);
  List<CharacterListView> selectedCharacters =
      <CharacterListView>[].toList(growable: true);
  List<String> memberCharacterIds = [];
  List<String> memberGroupIds = [];
  List<String> fatherGroupIds = [];
  TextEditingController searchBarController = TextEditingController();
  bool _initialDataLoaded = false;

  Future<ListCharacterResponse?> listCharacters() async {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 12,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: CharacterFilter(
            languageCode: I18nHelper.getLanguageCode(),
            userId: getIt<User>().id,
            excludedCharacterIds: [
              ...memberCharacterIds,
              ...selectedCharacters.map((character) => character.id).toList()
            ]));
    return await getIt<CharacterDao>().listCharacter(listCharacterRequest);
  }

  Future<ListGroupResponse?> listGroups() async {
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 12,
        pageIndex: 1,
        sortKeys: [],
        groupFilter: GroupFilter(
            languageCode: I18nHelper.getLanguageCode(),
            userId: getIt<User>().id,
            excludedGroupIds: [
              ...fatherGroupIds,
              widget.fatherGroup.id,
            ]));
    return await getIt<GroupDao>().listGroups(listGroupRequest);
  }

  _searchCharacter(Function panelState) {
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    characterFilter.userId = getIt<User>().id;
    characterFilter.name = searchBarController.text;
    characterFilter.excludedCharacterIds = [
      ...memberCharacterIds,
      ...selectedCharacters.map((character) => character.id).toList()
    ];
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 12,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: characterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      panelState(() {
        characters = List<CharacterListView>.of(value!.characters);
      });
    });
  }

  _searchGroup(Function panelState) {
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    groupFilter.name = searchBarController.text;
    groupFilter.userId = getIt<User>().id;
    groupFilter.excludedGroupIds = [
      widget.fatherGroup.id,
      ...widget.fatherGroup.fatherGroups.map((e) => e.id).toList(),
      ...selectedGroups.map((group) => group.id).toList()
    ];
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 12, pageIndex: 1, sortKeys: [], groupFilter: groupFilter);
    Future<ListGroupResponse?> listGroupResponse =
        getIt<GroupDao>().listGroups(listGroupRequest);
    listGroupResponse.then((value) {
      panelState(() {
        groups = List<GroupListView>.of(value!.groups);
      });
    });
  }

  _updateData(List<dynamic> widgets) {
    characters = List<CharacterListView>.of(
        (widgets[0] as ListCharacterResponse).characters);
    groups = List<GroupListView>.of((widgets[1] as ListGroupResponse).groups);
  }

  @override
  void initState() {
    super.initState();
    memberCharacterIds =
        widget.fatherGroup.characters.map((e) => e.id!).toList();
    memberGroupIds = widget.fatherGroup.subGroups.map((e) => e.id).toList();
    fatherGroupIds = widget.fatherGroup.fatherGroups.map((e) => e.id).toList();
    characterFilter.excludedCharacterIds = memberCharacterIds;
    groupFilter.excludedGroupIds = [widget.fatherGroup.id, ...fatherGroupIds];
    myFuture = Future.wait([listCharacters(), listGroups()]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    selectedController.dispose();
    selectableController.dispose();
    searchBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture as Future<List<dynamic>>,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!_initialDataLoaded) {
              _updateData(snapshot.data!);
              _initialDataLoaded = true;
            }
            return StatefulBuilder(builder: (context, panelState) {
              final screenSize = MediaQuery.of(context).size;
              final dialogWidth =
                  screenSize.width < 430 ? screenSize.width - 24 : 390.0;
              final dialogHeight = screenSize.height * 0.86;

              return SizedBox(
                width: dialogWidth,
                height: dialogHeight.clamp(520.0, 760.0).toDouble(),
                child: Card(
                  elevation: 3,
                  color: Colors.white,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: getSelectionPanel(context, panelState),
                        ),
                      ),
                      _buildActionBar(context, panelState),
                    ],
                  ),
                ),
              );
            });
          } else {
            return SizedBox(
              width: 360,
              height: 220,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.loading,
                    style: OnepieceFonts.loadingFont,
                  ),
                ),
              ),
            );
          }
        });
  }

  Widget _buildHeader(BuildContext context) {
    final isGroupMode = GroupCategory.group == widget.fatherGroup.groupCategory;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: OnepieceColors.fancyBlue.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              isGroupMode ? Icons.account_tree_outlined : Icons.group_add,
              color: OnepieceColors.fancyBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectNewMembers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnepieceFonts.smallHeaderStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  I18nHelper.getDisplayNameFromI18n(widget.fatherGroup.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnepieceFonts.contentStyle.copyWith(
                    color: OnepieceColors.menuIconColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, Function panelState) {
    final hasSelection = itemSelected(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: !hasSelection
                  ? null
                  : () {
                      panelState(() {
                        groups = [...groups, ...selectedGroups];
                        characters = [...characters, ...selectedCharacters];
                        selectedGroups = [];
                        selectedCharacters = [];
                      });
                    },
              child: Text(AppLocalizations.of(context)!.reselect),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: !hasSelection ? null : _submitSelection,
              child: Text(AppLocalizations.of(context)!.submitForm),
            ),
          ),
        ],
      ),
    );
  }

  void _submitSelection() {
    if (GroupCategory.group == widget.fatherGroup.groupCategory) {
      getIt<GroupDao>().addGroup(AddGroupRequest(
          fatherGroupId: widget.fatherGroup.id,
          childGroupIds: selectedGroups.map((e) => e.id).toList()));
    } else {
      getIt<GroupDao>().addCharacter(AddCharacterRequest(
          groupId: widget.fatherGroup.id,
          characterIds: selectedCharacters.map((e) => e.id).toList()));
    }
    Navigator.pop(context);
    AppRouter.router.replaceNamed('groupDetails',
        extra: widget.fatherGroup.id,
        pathParameters: {
          'name': I18nHelper.getDisplayNameFromI18n(widget.fatherGroup.name)
        });
  }

  Widget _getSearchBar(BuildContext context, Function panelState) {
    return SizedBox(
      height: 38,
      child: TextFormField(
        controller: searchBarController,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: OnepieceColors.menuHoverColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: OnepieceColors.menuHoverColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: OnepieceColors.fancyGreen, width: 1.6)),
          prefixIcon: const Icon(Icons.search, size: 18),
          hintText: AppLocalizations.of(context)!.search,
        ),
        onChanged: (value) {
          if (_timer?.isActive ?? false) _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 500), () {
            widget.fatherGroup.groupCategory == GroupCategory.group
                ? _searchGroup(panelState)
                : _searchCharacter(panelState);
          });
        },
      ),
    );
  }

  Widget getSelectionPanel(BuildContext context, Function panelState) {
    final isGroupMode = GroupCategory.group == widget.fatherGroup.groupCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: AppLocalizations.of(context)!.selected,
          icon: Icons.check_circle_outline,
          controller: selectedController,
          flex: 2,
          child: isGroupMode
              ? _getSelectedGroupWall(context, panelState)
              : _getSelectedCharacterWall(context, panelState),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.selectable,
          icon: Icons.manage_search,
          controller: selectableController,
          flex: 3,
          trailing: SizedBox(
            width: 170,
            child: _getSearchBar(context, panelState),
          ),
          child: isGroupMode
              ? _getGroupWall(context, panelState)
              : _getCharacterWall(context, panelState),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ScrollController controller,
    required int flex,
    required Widget child,
    Widget? trailing,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: OnepieceColors.menuHoverColor.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: OnepieceColors.fancyBlue),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: OnepieceFonts.navigationTopBarStyleClickable
                        .copyWith(fontSize: 14),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedCharacterWall(BuildContext context, Function panelState) {
    if (selectedCharacters.isEmpty) {
      return _buildEmptySelection();
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        return _buildCharacterGrid(
          constraint.maxWidth,
          selectedCharacters,
          onTap: (index) {
            panelState(() {
              final character = selectedCharacters.removeAt(index);
              if (!characters.any((item) => item.id == character.id)) {
                characters.insert(0, character);
              }
            });
          },
          selected: true,
        );
      },
    );
  }

  Widget _getCharacterWall(BuildContext context, Function panelState) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return _buildCharacterGrid(
          constraint.maxWidth,
          characters,
          onTap: (index) {
            panelState(() {
              selectedCharacters.add(characters[index]);
              characters.removeAt(index);
            });
          },
        );
      },
    );
  }

  Widget _getSelectedGroupWall(BuildContext context, Function panelState) {
    if (selectedGroups.isEmpty) {
      return _buildEmptySelection();
    }
    return LayoutBuilder(builder: (context, constraint) {
      return _buildGroupGrid(
        constraint.maxWidth,
        selectedGroups,
        onTap: (index) {
          panelState(() {
            final group = selectedGroups.removeAt(index);
            if (!groups.any((item) => item.id == group.id)) {
              groups.insert(0, group);
            }
          });
        },
        selected: true,
      );
    });
  }

  Widget _getGroupWall(BuildContext context, Function panelState) {
    return LayoutBuilder(builder: (context, constraint) {
      return _buildGroupGrid(
        constraint.maxWidth,
        groups,
        onTap: (index) {
          panelState(() {
            selectedGroups.add(groups[index]);
            groups.removeAt(index);
          });
        },
      );
    });
  }

  Widget _buildCharacterGrid(
    double maxWidth,
    List<CharacterListView> items, {
    required void Function(int index) onTap,
    bool selected = false,
  }) {
    final crossAxisCount = (maxWidth / 104).floor().clamp(2, 4).toInt();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.76,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final character = items[index];
        return _buildMemberTile(
          imageUri: character.imageUri!,
          name: I18nHelper.getDisplayNameFromI18n(character.name),
          selected: selected,
          onTap: () => onTap(index),
        );
      },
    );
  }

  Widget _buildGroupGrid(
    double maxWidth,
    List<GroupListView> items, {
    required void Function(int index) onTap,
    bool selected = false,
  }) {
    final crossAxisCount = (maxWidth / 104).floor().clamp(2, 4).toInt();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.76,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final group = items[index];
        return _buildMemberTile(
          imageUri: group.imageUri!,
          name: I18nHelper.getDisplayNameFromI18n(group.name),
          selected: selected,
          onTap: () => onTap(index),
        );
      },
    );
  }

  Widget _buildMemberTile({
    required String imageUri,
    required String name,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? OnepieceColors.liteFancyGreen.withValues(alpha: 0.65)
              : OnepieceColors.liteFancyBlue.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? OnepieceColors.fancyGreen.withValues(alpha: 0.35)
                : OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => imageUri,
                        width: 72,
                        borderWidth: 1.6,
                        borderRadios: 8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: OnepieceFonts.contentStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected
                      ? OnepieceColors.fancyGreen
                      : OnepieceColors.fancyBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  selected ? Icons.close : Icons.add,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySelection() {
    return Container(
      width: double.infinity,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: ImageHelper.getSvgIconWithColor(
          'images/svgs/question.svg', 54, 54, OnepieceColors.liteFancyBlue),
    );
  }

  bool itemSelected(BuildContext context) {
    return (selectedCharacters.isNotEmpty &&
            GroupCategory.group != widget.fatherGroup.groupCategory) ||
        (selectedGroups.isNotEmpty &&
            GroupCategory.group == widget.fatherGroup.groupCategory);
  }
}
