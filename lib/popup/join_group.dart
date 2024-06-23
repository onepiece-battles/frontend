import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/character_dao.dart';
import '../repository/group_dao.dart';
import '../utils/base64_helper.dart';
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
  TextEditingController characterNameController = TextEditingController();
  TextEditingController groupNameController = TextEditingController();
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
    characterFilter.name = characterNameController.text;
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
    groupFilter.name = groupNameController.text;
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
                                Row(
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
                                                          fatherGroupId: widget
                                                              .fatherGroup.id,
                                                          childGroupIds:
                                                              selectedGroups
                                                                  .map((e) =>
                                                                      e.id)
                                                                  .toList()));
                                                } else {
                                                  getIt<GroupDao>().addCharacter(
                                                      AddCharacterRequest(
                                                          groupId: widget
                                                              .fatherGroup.id,
                                                          characterIds:
                                                              selectedCharacters
                                                                  .map((e) =>
                                                                      e.id)
                                                                  .toList()));
                                                }
                                              },
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .submitForm))
                                  ],
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

  Widget getSelectionPanel(BuildContext context, Function panelState) {
    return SizedBox(
      width: 600,
      height: 600,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (GroupCategory.group == widget.fatherGroup.groupCategory)
              _getSelectedGroupWall(context, panelState),
            if (GroupCategory.group == widget.fatherGroup.groupCategory)
              _getGroupWall(context, panelState),
            if (GroupCategory.group != widget.fatherGroup.groupCategory)
              _getSelectedCharacterWall(context, panelState),
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
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(AppLocalizations.of(context)!.empty),
        ),
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
        return SizedBox(
          width: 880,
          height: ((selectedCharacters.length / crossAxisCount).ceil() * 110.0)
              .clamp(110, 440),
          child: GridView.builder(
            itemCount: selectedCharacters.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, int index) => Tooltip(
              preferBelow: true,
              message: I18nHelper.getDisplayNameFromI18n(
                  selectedCharacters[index].name),
              child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () {
                  panelState(() {
                    selectedCharacters.removeAt(index);
                    _searchCharacter(panelState);
                  });
                },
                child: ImageHelper.getRoundImageFrame(
                    100,
                    100,
                    2,
                    OnepieceColors.liteFancyBlue,
                    10,
                    Base64Helper.decode(
                        selectedCharacters[index].profileImage!)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getCharacterWall(BuildContext context, Function panelState) {
    if (characters.isEmpty) {
      return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(AppLocalizations.of(context)!.empty),
        ),
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
        return SizedBox(
          width: 880,
          height: ((characters.length / crossAxisCount).ceil() * 110.0)
              .clamp(110, 440),
          child: GridView.builder(
            itemCount: characters.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, int index) => Tooltip(
              preferBelow: true,
              message:
                  I18nHelper.getDisplayNameFromI18n(characters[index].name),
              child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () {
                  panelState(() {
                    selectedCharacters.add(characters[index]);
                    _searchCharacter(panelState);
                  });
                },
                child: ImageHelper.getRoundImageFrame(
                    100,
                    100,
                    2,
                    OnepieceColors.liteFancyBlue,
                    10,
                    Base64Helper.decode(characters[index].profileImage!)),
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(AppLocalizations.of(context)!.empty),
          ),
        ],
      );
    }
    return LayoutBuilder(builder: (context, constraint) {
      int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
      return SizedBox(
        width: 880,
        height: ((selectedGroups.length / crossAxisCount).ceil() * 110.0)
            .clamp(110, 400),
        child: GridView.builder(
          itemCount: selectedGroups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemBuilder: (BuildContext context, int index) => Tooltip(
            message:
                I18nHelper.getDisplayNameFromI18n(selectedGroups[index].name),
            preferBelow: true,
            child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () {
                  panelState(() {
                    selectedGroups.removeAt(index);
                    _searchGroup(panelState);
                  });
                },
                child: ImageHelper.getRoundImageFrame(
                    100,
                    100,
                    2,
                    OnepieceColors.liteFancyBlue,
                    10,
                    Base64Helper.decode(selectedGroups[index].profileImage!))),
          ),
        ),
      );
    });
  }

  Widget _getGroupWall(BuildContext context, Function panelState) {
    if (groups.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(AppLocalizations.of(context)!.empty),
          ),
        ],
      );
    }
    return LayoutBuilder(builder: (context, constraint) {
      int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
      return SizedBox(
        width: 880,
        height:
            ((groups.length / crossAxisCount).ceil() * 110.0).clamp(110, 400),
        child: GridView.builder(
          itemCount: groups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemBuilder: (BuildContext context, int index) => Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(groups[index].name),
            preferBelow: true,
            child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () {
                  panelState(() {
                    selectedGroups.add(groups[index]);
                    _searchGroup(panelState);
                  });
                },
                child: ImageHelper.getRoundImageFrame(
                    100,
                    100,
                    2,
                    OnepieceColors.liteFancyBlue,
                    10,
                    Base64Helper.decode(groups[index].profileImage!))),
          ),
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
