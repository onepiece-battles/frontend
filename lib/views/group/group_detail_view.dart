import 'dart:typed_data';
import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/popup/join_group.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/utils/nested_scroll_helper.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/base64_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/permission_check.dart';
import 'group_detail_controller.dart';

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
  final ScrollController _pageScrollController = ScrollController();
  late Future<GroupFullView?> _groupFuture;
  String? _preparedGroupId;
  late GroupFullView groupFullView;
  List<CharacterInGroupView> characters = [];
  List<Group> subGroups = [];
  final Map<String, CharacterFullView> _characterCombatCache = {};
  final Set<String> _loadingCharacterCombatIds = {};
  late GroupCategory selectedGroupCategory;
  String? selectedImage;
  bool _basicInfoEditable = false;
  bool _editButtonVisible = false;
  final GroupDetailController _controller = GroupDetailController();

  @override
  void initState() {
    super.initState();
    _groupFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant GroupDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _preparedGroupId = null;
      _groupFuture = _loadData();
    }
  }

  @override
  void dispose() {
    groupNameController.dispose();
    scrollController.dispose();
    _pageScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<GroupFullView?> _loadData() {
    return _controller
        .getGroupFullView(GetGroupRequest(id: widget.groupId));
  }

  void _prepareData(GroupFullView group) {
    if (_preparedGroupId == group.id) return;
    _preparedGroupId = group.id;
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
            ResourceType.GROUP,
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

  Widget _buildMobileLayout(BuildContext context) {
    final catMap = _getCategoryMap(context);
    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header: image + name + category
        Center(
            child: Column(children: [
          ImageLazyLoader(
              uriProvider: () => groupFullView.imageUri ?? '',
              width: 120,
              borderWidth: 2,
              borderRadios: 15,
              fullImage: true),
          const SizedBox(height: 8),
          Text(I18nHelper.getDisplayNameFromI18n(groupFullView.name),
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          OnepieceTag.getGroupTag(groupFullView.groupCategory!,
              catMap[groupFullView.groupCategory]!),
          if (_editButtonVisible) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _basicInfoEditable = !_basicInfoEditable),
              icon: Icon(_basicInfoEditable ? Icons.check : Icons.edit,
                  size: 14, color: OnepieceColors.fancyBlue),
              label: Text(
                  _basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  style: const TextStyle(
                      fontSize: 11, color: OnepieceColors.fancyBlue)),
            ),
          ],
        ])),
        const SizedBox(height: 12),
        // Basic info form (if editable)
        if (_basicInfoEditable)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.basicInfo,
                          style:
                              OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                      const SizedBox(height: 10),
                      ..._buildMobileGroupForm(context),
                    ])),
          ),
        const SizedBox(height: 12),
        // Members
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _getMembersPanel(context),
        ),
      ]),
    );
  }

  List<Widget> _buildMobileGroupForm(BuildContext context) {
    // Simplified form — reuse existing controller methods
    return [
      SizedBox(
          height: 35,
          child: TextFormField(
            controller: groupNameController,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                disabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.menuHoverColor)),
                enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.menuHoverColor)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                prefixIcon: const Icon(Icons.edit, size: 18),
                labelText: AppLocalizations.of(context)!.name),
          )),
    ];
  }

  Map<GroupCategory, String> _getCategoryMap(BuildContext context) =>
      <GroupCategory, String>{
        GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
        GroupCategory.marine: AppLocalizations.of(context)!.marine,
        GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
        GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
        GroupCategory.group: AppLocalizations.of(context)!.group,
        GroupCategory.other: AppLocalizations.of(context)!.otherType,
        GroupCategory.revolutionArmy:
            AppLocalizations.of(context)!.revolutionaryArmy,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _groupFuture,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return const SizedBox.shrink();
          }
          _prepareData(snapshot.data);
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow =
                  ResponsiveBreakpoints.isMobileFromConstraints(constraints);
              final divW = isNarrow ? constraints.maxWidth - 30 : 900.0;
              return Stack(
                children: [
                  if (isNarrow)
                    _buildMobileLayout(context)
                  else
                    SingleChildScrollView(
                      controller: _pageScrollController,
                      scrollDirection: Axis.vertical,
                      child: Center(
                        child: NestedHorizontalScrollView(
                          controller: scrollController,
                          verticalParentController: _pageScrollController,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: _getBasicInfo(context),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: SizedBox(
                                  width: divW,
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
                                            extra:
                                                groupFullView.previousGroup!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
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
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      groupFullView
                                                          .nextGroup!.name)
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
            },
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
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      basicInfoState(() {
                        _basicInfoEditable = !_basicInfoEditable;
                        if (!_basicInfoEditable) {
                          if (groupFullView.groupCategory !=
                                  selectedGroupCategory ||
                              I18nHelper.getDisplayNameFromI18n(
                                      groupFullView.name) !=
                                  groupNameController.text) {
                            Group group = Group(
                                id: groupFullView.id,
                                groupCategory: selectedGroupCategory,
                                name: I18nHelper.getI18nFromDisplayName(
                                    groupFullView.name!,
                                    groupNameController.text));
                            final router = GoRouter.of(context);
                            final alertHint =
                                AppLocalizations.of(context)!.hint;
                            final showAlert =
                                OnepieceAlert.createAlertShower(context);
                            _controller.updateGroups(group).then((value) {
                              if (!mounted) return;
                              showAlert(
                                  alertHint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                router.goNamed('groupDetails',
                                    extra: groupFullView.id,
                                    pathParameters: {
                                      'name': I18nHelper.getDisplayNameFromI18n(
                                          group.name)
                                    });
                              }
                            });
                          }
                          if (selectedImage != null) {
                            final router2 = GoRouter.of(context);
                            final alertHint2 =
                                AppLocalizations.of(context)!.hint;
                            final showAlert2 =
                                OnepieceAlert.createAlertShower(context);
                            _controller
                                .addImage(UploadImageRequest(
                                    type: ResourceType.GROUP,
                                    resourceId: groupFullView.id,
                                    image: selectedImage!))
                                .then((value) {
                              if (!mounted) return;
                              showAlert2(
                                  alertHint2,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              router2.goNamed('groupDetails',
                                  extra: groupFullView.id,
                                  pathParameters: {
                                    'name': I18nHelper.getDisplayNameFromI18n(
                                        groupFullView.name)
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
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: _basicInfoEditable
                ? () async {
                    final alertTitle = AppLocalizations.of(context)!.alert;
                    final alertMsg =
                        AppLocalizations.of(context)!.imageSizeExceedsLimit;
                    final showAlert = OnepieceAlert.createAlertShower(context);
                    basicInfoState(() async {
                      XFile? pickedImage =
                          await OnepieceImagePicker.pickWebImage();
                      Uint8List imageInByte = await pickedImage!.readAsBytes();
                      if (!ImageHelper.isValidImageSize(
                          500 * 1024, imageInByte)) {
                        showAlert(alertTitle, alertMsg);
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
                      uriProvider: () => groupFullView.imageUri!,
                      width: 200,
                      borderWidth: 3,
                      borderRadios: 20,
                      fullImage: true)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final panelWidth = isNarrow ? availableWidth : 760.0;
        final contentWidth = isNarrow
            ? (panelWidth - 32 > 280 ? panelWidth - 32 : 280.0)
            : 700.0;

        return SizedBox(
          width: panelWidth,
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isNarrow ? 12 : 18, 14, isNarrow ? 12 : 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          groupFullView.groupCategory == GroupCategory.group
                              ? AppLocalizations.of(context)!.groupStructure
                              : AppLocalizations.of(context)!.groupMember,
                          style: OnepieceFonts.headerStyle.copyWith(
                            fontSize: isNarrow ? 18 : 22,
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
