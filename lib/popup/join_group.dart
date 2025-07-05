import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:openapi/api.dart';
import 'package:get_it/get_it.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/character_dao.dart';
import '../repository/group_dao.dart';
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
  ScrollController verticalController = ScrollController();
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
        characters = value!.characters;
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
        groups = value!.groups;
      });
    });
  }

  _updateData(List<dynamic> widgets) {
    characters = (widgets[0] as ListCharacterResponse).characters;
    groups = (widgets[1] as ListGroupResponse).groups;
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
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture as Future<List<dynamic>>,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data!);
            return Stack(
              children: [
                SizedBox(
                  width: 800,
                  child: SingleChildScrollView(
                    controller: verticalController,
                    scrollDirection: Axis.vertical,
                    child: Center(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:
                              StatefulBuilder(builder: (context, panelState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                getSelectionPanel(context, panelState),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: SizedBox(
                                    width: 700,
                                    child: Divider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  child: SizedBox(
                                    width: 700,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                            onPressed: !itemSelected(context)
                                                ? null
                                                : () {
                                                    setState(() {
                                                      selectedGroups = [];
                                                      selectedCharacters = [];
                                                    });
                                                  },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .reselect)),
                                        ElevatedButton(
                                            onPressed: !itemSelected(context)
                                                ? null
                                                : () {
                                                    if (GroupCategory.group ==
                                                        widget.fatherGroup
                                                            .groupCategory) {
                                                      getIt<GroupDao>().addGroup(
                                                          AddGroupRequest(
                                                              fatherGroupId:
                                                                  widget
                                                                      .fatherGroup
                                                                      .id,
                                                              childGroupIds:
                                                                  selectedGroups
                                                                      .map((e) =>
                                                                          e.id)
                                                                      .toList()));
                                                    } else {
                                                      getIt<GroupDao>().addCharacter(
                                                          AddCharacterRequest(
                                                              groupId: widget
                                                                  .fatherGroup
                                                                  .id,
                                                              characterIds:
                                                                  selectedCharacters
                                                                      .map((e) =>
                                                                          e.id)
                                                                      .toList()));
                                                    }
                                                    Navigator.pop(context);
                                                    context.replaceNamed(
                                                        'groupDetails',
                                                        extra: widget
                                                            .fatherGroup.id,
                                                        pathParameters: {
                                                          'name': I18nHelper
                                                              .getDisplayNameFromI18n(
                                                                  widget
                                                                      .fatherGroup
                                                                      .name)
                                                        });
                                                  },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .submitForm)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                )
                              ],
                            );
                          })),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
  }

  Widget _getSearchBar(BuildContext context, Function panelState) {
    return SizedBox(
      width: 200,
      height: 35,
      child: TextFormField(
        controller: searchBarController,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          prefixIcon: const Icon(Icons.search),
          hintText: AppLocalizations.of(context)!.name,
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
    return SizedBox(
      width: 700,
      height: 700,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.selectNewMembers,
                  style: OnepieceFonts.smallHeaderStyle,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.selected,
              style: OnepieceFonts.navigationTopBarStyleClickable,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 700,
                child: Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
              ),
            ),
            if (GroupCategory.group == widget.fatherGroup.groupCategory)
              _getSelectedGroupWall(context, panelState),
            if (GroupCategory.group != widget.fatherGroup.groupCategory)
              _getSelectedCharacterWall(context, panelState),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 700,
                child: Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.selectable,
                    style: OnepieceFonts.navigationTopBarStyleClickable,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _getSearchBar(context, panelState),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (GroupCategory.group == widget.fatherGroup.groupCategory)
              _getGroupWall(context, panelState),
            if (GroupCategory.group != widget.fatherGroup.groupCategory)
              _getCharacterWall(context, panelState),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedCharacterWall(BuildContext context, Function panelState) {
    if (selectedCharacters.isEmpty) {
      return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            child: ImageHelper.getSvgIconWithColor('images/svgs/question.svg',
                100, 100, OnepieceColors.liteFancyBlue),
          ),
        )
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
        return SizedBox(
          width: 880,
          height: ((selectedCharacters.length / crossAxisCount).ceil() * 120.0)
              .clamp(120, 480),
          child: GridView.builder(
            itemCount: selectedCharacters.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.8,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, int index) => InkWell(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () {
                panelState(() {
                  selectedCharacters.removeAt(index);
                  _searchCharacter(panelState);
                });
              },
              child: Column(
                children: [
                  Flexible(
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () =>
                              selectedCharacters[index].imageUri!,
                          width: 100,
                          borderWidth: 2,
                          borderRadios: 10)),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(I18nHelper.getDisplayNameFromI18n(
                      selectedCharacters[index].name))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getCharacterWall(BuildContext context, Function panelState) {
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
        return SizedBox(
          width: 880,
          height: ((characters.length / crossAxisCount).ceil() * 120.0)
              .clamp(120, 480),
          child: GridView.builder(
            itemCount: characters.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.8,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, int index) => InkWell(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () {
                panelState(() {
                  selectedCharacters.add(characters[index]);
                  _searchCharacter(panelState);
                });
              },
              child: Column(
                children: [
                  Flexible(
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () => characters[index].imageUri!,
                          width: 100,
                          borderWidth: 2,
                          borderRadios: 10)),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                      I18nHelper.getDisplayNameFromI18n(characters[index].name))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getSelectedGroupWall(BuildContext context, Function panelState) {
    if (selectedGroups.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2.0)),
            ),
            child: FittedBox(
              fit: BoxFit.fill,
              child: ImageHelper.getSvgIconWithColor('images/svgs/question.svg',
                  100, 100, OnepieceColors.liteFancyBlue),
            ),
          )
        ],
      );
    }
    return LayoutBuilder(builder: (context, constraint) {
      int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
      return SizedBox(
        width: 880,
        height: ((selectedGroups.length / crossAxisCount).ceil() * 120.0)
            .clamp(120, 480),
        child: GridView.builder(
          itemCount: selectedGroups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemBuilder: (BuildContext context, int index) => InkWell(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () {
                panelState(() {
                  selectedGroups.removeAt(index);
                  _searchGroup(panelState);
                });
              },
              child: Column(
                children: [
                  Flexible(
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => selectedGroups[index].imageUri!,
                        width: 100,
                        borderWidth: 2,
                        borderRadios: 10),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(I18nHelper.getDisplayNameFromI18n(
                      selectedGroups[index].name))
                ],
              )),
        ),
      );
    });
  }

  Widget _getGroupWall(BuildContext context, Function panelState) {
    return LayoutBuilder(builder: (context, constraint) {
      int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
      return SizedBox(
        width: 880,
        height:
            ((groups.length / crossAxisCount).ceil() * 110.0).clamp(120, 480),
        child: GridView.builder(
          itemCount: groups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemBuilder: (BuildContext context, int index) => InkWell(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () {
                panelState(() {
                  selectedGroups.add(groups[index]);
                  _searchGroup(panelState);
                });
              },
              child: Column(
                children: [
                  Flexible(
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => groups[index].imageUri!,
                        width: 100,
                        borderWidth: 2,
                        borderRadios: 10),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(I18nHelper.getDisplayNameFromI18n(groups[index].name))
                ],
              )),
        ),
      );
    });
  }

  bool itemSelected(BuildContext context) {
    return (selectedCharacters.isNotEmpty &&
            GroupCategory.group != widget.fatherGroup.groupCategory) ||
        (selectedGroups.isNotEmpty &&
            GroupCategory.group == widget.fatherGroup.groupCategory);
  }
}
