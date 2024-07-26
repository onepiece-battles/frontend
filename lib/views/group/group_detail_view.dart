import 'dart:typed_data';
import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/components/image_cache_manager.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/popup/join_group.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/permission_check.dart';

GetIt getIt = GetIt.instance;

class GroupDetailView extends StatefulWidget {
  final String groupId;
  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  late GroupNode root;
  TextEditingController groupNameController = TextEditingController();
  ScrollController scrollController = ScrollController();
  late GroupFullView groupFullView;
  List<CharacterInGroupView> characters = [];
  List<Group> subGroups = [];
  late GroupCategory selectedGroupCategory;
  String? selectedImage;
  bool _basicInfoEditable = false;
  bool _editButtonVisible = false;
  final double _dividerWidth = 900;

  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<GroupDao>()
        .getGroupFullView(GetGroupRequest(id: widget.groupId));
  }

  void _prepareData(GroupFullView group) {
    groupFullView = group;
    characters = group.characters;
    subGroups = group.subGroups;
    selectedGroupCategory = group.groupCategory!;
    groupNameController.text = I18nHelper.getDisplayNameFromI18n(group.name!);
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
    _editButtonVisible = PermissionCheck.checkPermission(
            getIt<User>().loginRoleResourcesPermissionMap,
            ResourceType.CHARACTER,
            Permission.UPDATE) &&
        PermissionCheck.isMyResource(
            groupFullView.creationRecord!.userId!,
            groupFullView.creationRecord!.roleId!,
            getIt<User>().id,
            getIt<User>().loginRoleId!);
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: _getBasicInfo(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            width: _dividerWidth,
                            child: const Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: _getMembersPanel(context),
                        ),
                        // bottom space
                        const SizedBox(
                          height: 60,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tooltip(
                          message: groupFullView.previousGroup == null
                              ? ""
                              : I18nHelper.getDisplayNameFromI18n(
                                  groupFullView.previousGroup!.name),
                          child: ElevatedButton(
                            onPressed: groupFullView.previousGroup == null
                                ? null
                                : () {
                                    context.goNamed('groupDetails',
                                        extra: groupFullView.previousGroup!.id,
                                        pathParameters: {
                                          'name':
                                              I18nHelper.getDisplayNameFromI18n(
                                                  groupFullView
                                                      .previousGroup!.name)
                                        });
                                  },
                            child: const Icon(Icons.arrow_back),
                          ),
                        ),
                        Tooltip(
                          message: groupFullView.nextGroup == null
                              ? ""
                              : I18nHelper.getDisplayNameFromI18n(
                                  groupFullView.nextGroup!.name),
                          child: ElevatedButton(
                            onPressed: groupFullView.nextGroup == null
                                ? null
                                : () {
                                    context.goNamed('groupDetails',
                                        extra: groupFullView.nextGroup!.id,
                                        pathParameters: {
                                          'name':
                                              I18nHelper.getDisplayNameFromI18n(
                                                  groupFullView.nextGroup!.name)
                                        });
                                  },
                            child: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
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
      },
    );
  }

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, basicInfoState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.basicInfo,
                style: OnepieceFonts.headerStyle,
              ),
              const SizedBox(
                width: 15,
              ),
              if (_editButtonVisible)
                Tooltip(
                  message: _basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.white,
                    onTap: () {
                      basicInfoState(() {
                        _basicInfoEditable = !_basicInfoEditable;
                        if (!_basicInfoEditable) {
                          Group group = Group(
                              id: groupFullView.id,
                              groupCategory: selectedGroupCategory,
                              name: I18nHelper.getI18nFromDisplayName(
                                  groupFullView.name!,
                                  groupNameController.text));
                          if (groupFullView.groupCategory !=
                                  selectedGroupCategory ||
                              groupFullView.name.toString() !=
                                  I18nHelper.getI18nFromDisplayName(
                                          groupFullView.name!,
                                          groupNameController.text)
                                      .toString()) {
                            getIt<GroupDao>().updateGroups(group).then((value) {
                              OnepieceAlert.getBasicAlertDialogFunc(
                                  context,
                                  AppLocalizations.of(context)!.hint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                context.goNamed('groupDetails',
                                    extra: groupFullView.id,
                                    pathParameters: {
                                      'name': I18nHelper.getDisplayNameFromI18n(
                                          group.name)
                                    });
                              }
                            });
                          }
                          if (selectedImage != null) {
                            getIt<ImageDao>()
                                .addImage(UploadImageRequest(
                                    type: ResourceType.GROUP,
                                    resourceId: group.id,
                                    image: selectedImage!))
                                .then((value) {
                              OnepieceAlert.getBasicAlertDialogFunc(
                                  context,
                                  AppLocalizations.of(context)!.hint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              context.goNamed('groupDetails',
                                  extra: group.id,
                                  pathParameters: {
                                    'name': I18nHelper.getDisplayNameFromI18n(
                                        group.name)
                                  });
                            });
                          }
                        }
                      });
                    },
                    child: SizedBox(
                        width: 25,
                        height: 25,
                        child: !_basicInfoEditable
                            ? ImageHelper.getSvgIconWithColor(
                                'images/svgs/edit.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)
                            : ImageHelper.getSvgIconWithColor(
                                'images/svgs/check.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)),
                  ),
                ),
            ],
          ),
          InkWell(
            onTap: _basicInfoEditable
                ? () async {
                    basicInfoState(() async {
                      XFile? pickedImage =
                          await OnepieceImagePicker.pickWebImage();
                      Uint8List imageInByte = await pickedImage!.readAsBytes();
                      if (!ImageHelper.isValidImageSize(
                          500 * 1024, imageInByte)) {
                        OnepieceAlert.getBasicAlertDialogFunc(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!
                                .imageSizeExceedsLimit);
                        return;
                      }
                      basicInfoState(() {
                        selectedImage = Base64Helper.encode(imageInByte);
                      });
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: selectedImage == null
                  ? ImageLazyLoader(
                      key: UniqueKey(),
                      uriProvider: () => groupFullView.imageUri!,
                      width: 200,
                      borderWidth: 3,
                      borderRadios: 20)
                  : ImageHelper.getRoundImageFrame(
                      200,
                      200,
                      3,
                      OnepieceColors.liteFancyBlue,
                      20,
                      Base64Helper.decode(selectedImage!)),
            ),
          ),
          StringTextFormField(
              context,
              _basicInfoEditable,
              groupNameController,
              AppLocalizations.of(context)!.name,
              30,
              ImageHelper.getTextFormFieldIcon(
                  'images/character_digits_icon/name.svg', true, null),
              true),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ImageHelper.getTextFormFieldIcon(
                  'images/svgs/type.svg', true, 22),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 300,
                child: Text(
                  AppLocalizations.of(context)!.category,
                  style: OnepieceFonts.deepBlackHintFont,
                ),
              ),
            ],
          ),
          _getDropDownList(context, basicInfoState),
        ],
      );
    });
  }

  Widget _getDropDownList(BuildContext context, Function basicInfoState) {
    Map<GroupCategory, String> groupCategoryToDisplayName = {
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedGroupCategory,
          hint: Text(
            AppLocalizations.of(context)!.groupCategory,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: !_basicInfoEditable ||
                  GroupCategory.group == groupFullView.groupCategory
              ? null
              : (value) {
                  basicInfoState(() {
                    selectedGroupCategory = value! as GroupCategory;
                  });
                },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 35,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.liteFancyGreen,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: selectedGroupCategory != GroupCategory.group
              ? GroupCategory.values
                  .where((element) => element != GroupCategory.group)
                  .map((GroupCategory groupCategory) {
                  return DropdownMenuItem<GroupCategory>(
                    value: groupCategory,
                    child: Text(
                      groupCategoryToDisplayName[groupCategory]!,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList()
              : GroupCategory.values
                  .where((element) => element == GroupCategory.group)
                  .map((GroupCategory groupCategory) {
                  return DropdownMenuItem<GroupCategory>(
                    value: groupCategory,
                    child: Text(
                      groupCategoryToDisplayName[groupCategory]!,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  Widget _getMembersPanel(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter listState) {
      return SizedBox(
        width: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  groupFullView.groupCategory == GroupCategory.group
                      ? Text(
                          AppLocalizations.of(context)!.groupStructure,
                          style: OnepieceFonts.headerStyle,
                        )
                      : Text(
                          AppLocalizations.of(context)!.groupMember,
                          style: OnepieceFonts.headerStyle,
                        ),
                  const SizedBox(
                    width: 10,
                  ),
                  if (_editButtonVisible)
                    Tooltip(
                      message: _basicInfoEditable
                          ? AppLocalizations.of(context)!.add
                          : AppLocalizations.of(context)!.add,
                      child: InkWell(
                        hoverColor: Colors.transparent,
                        onTap: () {
                          listState(() {
                            _showDialog(context);
                          });
                        },
                        child: ImageHelper.getSvgIcon(
                            'images/svgs/add.svg', 30, 30),
                      ),
                    ),
                ],
              ),
            ),
            if (groupFullView.fatherGroups.isNotEmpty) getFatherList(context),
            const SizedBox(
              height: 10,
            ),
            if (groupFullView.characters.isNotEmpty)
              Text(
                AppLocalizations.of(context)!.thisGroup,
                style: OnepieceFonts.navigationTopBarStyleClickable,
              ),
            const SizedBox(
              height: 10,
            ),
            root.group.groupCategory == GroupCategory.group
                ? buildTreeNode(root, listState, false, 1)
                : buildCharacterList(context),
          ],
        ),
      );
    });
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
                            key: UniqueKey(),
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
    Map<GroupPosition, String> groupPositionToDisplayValue = {
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
    return SizedBox(
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
                expandedAlignment: Alignment.centerLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onExpansionChanged: (value) {},
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () => character.imageUri!,
                          width: 40,
                          borderWidth: 1.4,
                          borderRadios: 3),
                      onTap: () {
                        context.goNamed('characterDetails',
                            extra: character.id,
                            pathParameters: {
                              'name': I18nHelper.getDisplayNameFromI18n(
                                  character.name)
                            });
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        I18nHelper.getDisplayNameFromI18n(character.name!),
                      ),
                    )
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 3, 0, 3),
                    child: Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.position}: ",
                          style: OnepieceFonts.contentStyle,
                        ),
                        Text(
                          groupPositionToDisplayValue[character.position!]!,
                          style: OnepieceFonts.contentStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void handleExpansionChanged(
      bool isExpanded, GroupNode node, Function listState) {
    if (isExpanded && !node.childrenFetched) {
      // Simulate fetching children from the backend
      List<TreeNode> fetchedChildren = [];
      if (node.group.groupCategory == GroupCategory.group) {
        getIt<GroupDao>()
            .listChildGroups(ListChildGroupsRequest(groupId: node.group.id))
            .then((value) {
          fetchedChildren = value!.childGroups.map((e) {
            return GroupNode(fetchedChildren, false, e);
          }).toList();
          listState(() {
            node.children = fetchedChildren;
            node.childrenFetched = true;
          });
        });
      } else {
        getIt<GroupDao>()
            .listChildCharacters(
                ListChildCharactersRequest(groupId: node.group.id))
            .then((value) {
          fetchedChildren = value!.childCharacters.map((e) {
            return CharacterNode(fetchedChildren, false, e);
          }).toList();
          listState(() {
            node.children = fetchedChildren;
            node.childrenFetched = true;
          });
        });
      }
    }
  }

  Widget buildTreeNode(
      TreeNode node, Function listState, bool isChildCharacter, int level) {
    Map<GroupPosition, String> groupPositionToDisplayValue = {
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
    if (!isChildCharacter) {
      GroupNode actualNode = node as GroupNode;
      return ExpansionTile(
        childrenPadding: EdgeInsets.only(left: level * 20),
        title: Row(
          children: [
            InkWell(
              child: ImageLazyLoader(
                  key: UniqueKey(),
                  uriProvider: () => node.group.imageUri!,
                  width: 40,
                  borderWidth: 1.5,
                  borderRadios: 3),
              onTap: () {
                context.goNamed('groupDetails',
                    extra: node.group.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(node.group.name)
                    });
              },
            ),
            const SizedBox(
              width: 10,
            ),
            Text(I18nHelper.getDisplayNameFromI18n(actualNode.group.name!))
          ],
        ),
        onExpansionChanged: (isExpanded) =>
            handleExpansionChanged(isExpanded, actualNode, listState),
        children: actualNode.children
            .map((child) => buildTreeNode(
                child,
                listState,
                actualNode.group.groupCategory != GroupCategory.group,
                level + 1))
            .toList(),
      );
    } else {
      CharacterNode actualNode = node as CharacterNode;
      return ExpansionTile(
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
        expandedAlignment: Alignment.centerLeft,
        title: Row(
          children: [
            InkWell(
              child: ImageLazyLoader(
                  key: UniqueKey(),
                  uriProvider: () => actualNode.characterInGroupView.imageUri!,
                  width: 40,
                  borderWidth: 1.5,
                  borderRadios: 3),
              onTap: () {
                context.goNamed('characterDetails',
                    extra: node.characterInGroupView.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(
                          node.characterInGroupView.name)
                    });
              },
            ),
            const SizedBox(
              width: 10,
            ),
            Text(I18nHelper.getDisplayNameFromI18n(
                actualNode.characterInGroupView.name!)),
          ],
        ),
        children: [
          SizedBox(
            height: 30,
            child: Text(groupPositionToDisplayValue[
                node.characterInGroupView.position]!),
          )
        ],
      );
    }
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
