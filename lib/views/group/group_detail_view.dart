import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/utils/svg_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
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
  bool groupCategoryEditable = false;
  bool nameFieldEditable = false;

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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  child: Container(
                    width: 200,
                    height: 200,
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
                      child: Image.memory(
                          Base64Helper.decode(groupFullView.profileImage!)),
                    ),
                  ),
                ),
                _getName(
                    context,
                    AppLocalizations.of(context)!.name,
                    20,
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: ImageHelper.getSvgIconWithColor(
                          'images/character_digits_icon/name.svg',
                          30,
                          30,
                          OnepieceColors.fancyBlue),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _getDropDownList(context),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          groupCategoryEditable = !groupCategoryEditable;
                        });
                      },
                      splashRadius: 1,
                      icon: SizedBox(
                        width: 50,
                        height: 50,
                        child: ImageHelper.getSvgIconWithColor(
                            'images/svgs/edit.svg',
                            80,
                            80,
                            OnepieceColors.fancyBlue),
                      ),
                    ),
                  ],
                ),
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

  Widget _getName(
      BuildContext context, String label, int length, Widget? icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: groupNameController,
            enabled: nameFieldEditable,
            // maxLength: length,
            decoration: InputDecoration(
                prefixIcon: icon,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                contentPadding: const EdgeInsets.fromLTRB(20, 2, 10, 2)),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              groupCategoryEditable = !groupCategoryEditable;
            });
          },
          splashRadius: 1,
          icon: SizedBox(
            width: 50,
            height: 50,
            child: ImageHelper.getSvgIconWithColor(
                'images/svgs/edit.svg', 80, 80, OnepieceColors.fancyBlue),
          ),
        ),
      ],
    );
  }

  Widget _getDropDownList(BuildContext context) {
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
          onChanged: groupCategoryEditable == false
              ? null
              : (value) {
                  setState(() {
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
}
