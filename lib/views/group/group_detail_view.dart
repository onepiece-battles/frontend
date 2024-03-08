import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;

class GroupDetailView extends StatefulWidget {
  final String groupId;
  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  TextEditingController groupNameController = TextEditingController();
  ScrollController scrollController = ScrollController();
  late GroupFullView groupFullView;
  List<CharacterInGroupView> characters = [];
  late GroupCategory selectedGroupCategory;
  bool _basicInfoEditable = false;
  final ValueNotifier<bool> _onlyCurrentMember = ValueNotifier(false);

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
    selectedGroupCategory = group.groupCategory!;
    groupNameController.text = I18nHelper.getDisplayNameFromI18n(group.name!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return Stack(
            // alignment: Alignment.bottomCenter,
            children: [
              SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: _getBasicInfo(context),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
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
                                groupFullView.name!, groupNameController.text));
                        getIt<GroupDao>().updateGroups(group).then((value) {
                          OnepieceAlert.getBasicAlertDialogFunc(
                              context,
                              AppLocalizations.of(context)!.hint,
                              I18nHelper.getDisplayNameFromI18n(value!.result));
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ImageHelper.getRoundImageFrame(
                200,
                200,
                3,
                OnepieceColors.liteFancyBlue,
                20,
                Base64Helper.decode(groupFullView.profileImage!)),
          ),
          SizedBox(
            width: 300,
            child: Text(
              AppLocalizations.of(context)!.name,
              style: OnepieceFonts.deepBlackHintFont,
            ),
          ),
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: groupNameController,
              enabled: _basicInfoEditable,
              maxLength: 20,
              decoration: const InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.fromLTRB(5, 20, 10, 2)),
            ),
          ),
          SizedBox(
            width: 300,
            child: Text(
              AppLocalizations.of(context)!.category,
              style: OnepieceFonts.deepBlackHintFont,
            ),
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
      GroupCategory.worldGovernment:
          AppLocalizations.of(context)!.worldGovernment,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedGroupCategory,
          hint: Text(
            AppLocalizations.of(context)!.groupCategory,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: !_basicInfoEditable
              ? null
              : (value) {
                  basicInfoState(() {
                    selectedGroupCategory = value! as GroupCategory;
                  });
                },
          selectedItemBuilder: (context) {
            return GroupCategory.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    groupCategoryToDisplayName[selectedGroupCategory]!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 34,
              width: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.menuBackgroundColor,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: GroupCategory.values.map((GroupCategory groupCategory) {
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
    var charactersInside = characters;
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter listState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              AppLocalizations.of(context)!.groupMember,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.currentMember),
              IconButton(
                onPressed: () {
                  listState(() {
                    _onlyCurrentMember.value = !_onlyCurrentMember.value;
                    if (_onlyCurrentMember.value) {
                      charactersInside = characters
                          .where((element) => element.onceBelongedTo == false)
                          .toList();
                    } else {
                      charactersInside = characters;
                    }
                  });
                },
                splashRadius: 1,
                icon: _onlyCurrentMember.value
                    ? const Icon(
                        Icons.check_box,
                        color: OnepieceColors.fancyBlue,
                        size: 20,
                      )
                    : const Icon(
                        Icons.check_box_outline_blank,
                        color: OnepieceColors.fancyBlue,
                        size: 20,
                      ),
              ),
            ],
          ),
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: OnepieceColors.menuBackgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: charactersInside.length,
              itemBuilder: (context, index) {
                var character = charactersInside[index];
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
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(2.0)),
                              border: Border.all(
                                  color: OnepieceColors.fancyBlue,
                                  width: 2,
                                  style: BorderStyle.solid),
                            ),
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Padding(
                                padding: const EdgeInsets.all(1.0),
                                child: Image.memory(Base64Helper.decode(
                                    character.profileImage!)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              I18nHelper.getDisplayNameFromI18n(
                                  character.name!),
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
                                groupPositionToDisplayValue[
                                    character.position!]!,
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
          ),
        ],
      );
    });
  }
}
