import 'package:dropdown_button2/dropdown_button2.dart';
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

  late GroupFullView groupFullView;
  List<CharacterInGroupView> characters = [];
  late GroupCategory selectedGroupCategory;
  bool _basicInfoEditable = false;

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
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
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
                // _getMembersPanel(context),
              ],
            ),
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
              const SizedBox(width: 15,),
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
                            name: I18nHelper.setI18nFromDisplayName(
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
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                border: Border.all(
                    color: OnepieceColors.fancyBlue,
                    width: 5,
                    style: BorderStyle.solid),
              ),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Image.memory(
                      Base64Helper.decode(groupFullView.profileImage!)),
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
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

  // Widget _getMembersPanel(BuildContext context) {
  //
  // }
}
