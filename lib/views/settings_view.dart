import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/base64_helper.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _footButtonEnabled = false;
  SettingOriginalData settingOriginalData = SettingOriginalData();
  String locale = Intl.getCurrentLocale();
  String chosenImageName = "";
  Uint8List profileImage = Base64Helper.decode(getIt<User>().profileImage!);
  // Character character;
  @override
  void initState() {
    super.initState();
    settingOriginalData.setCurrentLocale(locale);
    settingOriginalData.setProfileImage(profileImage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _getAvatar(context),
        const Divider(
          height: 10,
          thickness: 1,
        ),
        _getLocalization(context),
        _getFootButtons(context)
      ],
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          AppLocalizations.of(context)!.avatarHeader,
          style: OnepieceFonts.headerStyle,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          AppLocalizations.of(context)!.avatarHeaderDescription,
          style: OnepieceFonts.contentStyle,
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              iconSize: 100,
              splashRadius: 10,
              splashColor: Colors.red,
              icon: Image.memory(profileImage),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadNewAvatar,
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
                      onPressed: () {
                        setState(() {
                          OnepieceImagePicker.pickWebImage()
                              .then((value) => profileImage = value!);
                          _footButtonEnabled = isModified(locale, profileImage);
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      chosenImageName != ""
                          ? chosenImageName
                          : AppLocalizations.of(context)!.noFileChosen,
                      style: OnepieceFonts.contentStyle,
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  AppLocalizations.of(context)!.maxFileSizeDescription,
                  style: OnepieceFonts.contentStyle,
                )
              ],
            )
          ],
        )
      ]),
    );
  }

  Widget _getLocalization(BuildContext context) {
    List<String> displayCharacterTypes = [
      AppLocalizations.of(context)!.chinese,
      AppLocalizations.of(context)!.english,
    ];
    String selectedItem = displayCharacterTypes.first;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          AppLocalizations.of(context)!.localizationHeader,
          style: OnepieceFonts.headerStyle,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          AppLocalizations.of(context)!.localizationDescription,
          style: OnepieceFonts.contentStyle,
        ),
        const SizedBox(
          height: 10,
        ),
        DropdownSearch<String>(
          items: displayCharacterTypes,
          selectedItem: selectedItem,
          onChanged: (value) {
            selectedItem = value!;
            setState(() {
              _footButtonEnabled = isModified(locale, profileImage);
            });
          },
        ),
      ]),
    );
  }

  Row _getFootButtons(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: !_footButtonEnabled
              ? null
              : () {
                  setState(() {
                    locale = settingOriginalData.locale;
                    profileImage = settingOriginalData.profileImage;
                  });
                },
          child: Text(AppLocalizations.of(context)!.cancelPopUp),
        ),
        ElevatedButton(
            onPressed: !_footButtonEnabled
                ? null
                : () {
                    var multipartImage =
                        MultipartFile.fromBytes("document", profileImage);
                    debugPrint("new image is:");
                    debugPrint(multipartImage.length.toString());
                    getIt<ImageDao>()
                        .addImage(
                            getIt<User>().id, ResourceType.USER, multipartImage)
                        .then((value) {
                      setState(() {
                        settingOriginalData.setProfileImage(profileImage);
                      });
                    });
                    // todo(yichi): update user locale here
                  },
            child: Text(AppLocalizations.of(context)!.submitForm)),
      ],
    );
  }

  bool isModified(String locale, Uint8List image) {
    return settingOriginalData.locale != locale ||
        settingOriginalData.profileImage != image;
  }
}

class SettingOriginalData {
  late Uint8List _profileImage;
  late String _currentLocale;

  void setProfileImage(Uint8List profileImage) {
    _profileImage = profileImage;
  }

  void setCurrentLocale(String locale) {
    _currentLocale = locale;
  }

  String get locale => _currentLocale;
  Uint8List get profileImage => _profileImage;
}
