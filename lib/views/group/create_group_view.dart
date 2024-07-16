import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/path_constants.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_validator.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/random_string_generator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

GetIt getIt = GetIt.instance;

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({Key? key}) : super(key: key);

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  // name controller
  TextEditingController groupNameEnController = TextEditingController(
      text: RandomStringGenerator.generateRandomName(
          8, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController groupNameChController = TextEditingController(
      text: RandomStringGenerator.generateRandomChineseName(
          3, getIt<User>().loginRole == UserRole.NIKA));

  GroupCategory selectedGroupCategory = GroupCategory.pirate;

  List<TextEditingController> groupControlList() {
    return <TextEditingController>[
      groupNameEnController,
      groupNameChController,
    ];
  }

  Uint8List _pickedImage = Uint8List(0);
  bool _newImagePicked = false;
  String _chosenImageName = "";
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                  child: Text(
                    AppLocalizations.of(context)!.basicInfo,
                    style: OnepieceFonts.headerStyle,
                  ),
                ),
                _getAvatar(context),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: groupNameChController,
                          validator: (value) {
                            if (value!.isWhiteSpace()) {
                              return AppLocalizations.of(context)!
                                  .requiredField;
                            }
                            if (!DataValidator.validName(value)) {
                              return AppLocalizations.of(context)!.invalidName;
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          maxLength: 30,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.groupName,
                            prefixIcon: const Icon(Icons.people),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 25,
                      ),
                      if (getIt<User>().loginRole == UserRole.NIKA)
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: groupNameEnController,
                            validator: (value) {
                              if (value!.isWhiteSpace()) {
                                return AppLocalizations.of(context)!
                                    .requiredField;
                              }
                              if (!DataValidator.validName(value)) {
                                return AppLocalizations.of(context)!
                                    .invalidName;
                              }
                              return null;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.groupName,
                              prefixIcon: const Icon(Icons.people),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 8, 10),
                      child: Text(
                        AppLocalizations.of(context)!.groupCategory,
                        style: OnepieceFonts.tableHeaderStyle,
                      ),
                    ),
                    _getDropDownList(context),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Divider(
                    height: 2,
                  ),
                ),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          ),
        ),
        _getFootBar(context)
      ],
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 15.0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: _pickedImage.isEmpty
                  ? ClipOval(
                      child: Image.asset(PathConstants.luffyFlag),
                    )
                  : ClipOval(
                      child: Image.memory(_pickedImage),
                    ),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadGroupEmblem,
                  style: const TextStyle(
                      color: OnepieceFonts.headerFontColor,
                      fontSize: OnepieceFonts.contentFontSize,
                      fontWeight: OnepieceFonts.headerFontWeight),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        XFile? pickedImage =
                            await OnepieceImagePicker.pickWebImage();
                        Uint8List imageInByte =
                            await pickedImage!.readAsBytes();
                        _pickedImage = imageInByte;
                        if (!ImageHelper.isValidImageSize(
                            500 * 1024, imageInByte)) {
                          OnepieceAlert.getBasicAlertDialogFunc(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!
                                  .imageSizeExceedsLimit);
                          return;
                        }
                        setState(() {
                          _chosenImageName = pickedImage.name;
                          _newImagePicked = true;
                        });
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 200,
                      child: Text(
                        _chosenImageName != ""
                            ? _chosenImageName
                            : AppLocalizations.of(context)!.noFileChosen,
                        style: OnepieceFonts.contentStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  AppLocalizations.of(context)!.maxFileSize500,
                  style: OnepieceFonts.contentStyle,
                )
              ],
            )
          ],
        )
      ]),
    );
  }

  Widget _getDropDownList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayName = {
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government:
          AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.other:AppLocalizations.of(context)!.otherType,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.revolutionArmy: AppLocalizations.of(context)!.revolutionaryArmy,
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
          onChanged: (value) {
            setState(() {
              selectedGroupCategory = value!;
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

  Widget _getFootBar(BuildContext context) {
    return Positioned(
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
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.clearForm),
                  onPressed: () {
                    setState(() {
                      groupControlList().forEach((element) {
                        element.clear();
                      });
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!_newImagePicked) {
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context,
                          AppLocalizations.of(context)!.hint,
                          AppLocalizations.of(context)!.groupEmblemRequired);
                      return;
                    }
                    CreateGroupRequest createGroupRequest = CreateGroupRequest(
                      name: RandomStringGenerator.generateI18n(
                          groupNameEnController.text,
                          groupNameChController.text),
                      groupCategory: selectedGroupCategory,
                    );
                    getIt<GroupDao>()
                        .createGroup(createGroupRequest)
                        .then((createGroupResponse) {
                      var encodedImage = Base64Helper.encode(_pickedImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: createGroupResponse!.id.toString(),
                              image: encodedImage,
                              type: ResourceType.GROUP);
                      getIt<ImageDao>()
                          .addImage(uploadImageRequest)
                          .then((value) => context.goNamed('groupDetails',
                          extra: createGroupResponse.id,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(createGroupResponse.name)
                          }));
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
  }
}
