import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_fonts.dart';
import '../main.dart';
import '../repository/user_dao.dart';
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
  Uint8List profileImage = Base64Helper.decode(getIt<User>().profileImage!);
  String chosenImageName = "";
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
        const Divider(
          height: 10,
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _getFootButtons(context),
        )
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
                        OnepieceImagePicker.pickWebImage().then((value) {
                          XFile image = value!;
                          setState(() {
                            chosenImageName = image.name;
                            image
                                .readAsBytes()
                                .then((value) => profileImage = value);
                            _footButtonEnabled =
                                isModified(locale, profileImage);
                          });
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
    Map<String, String> localeToDisplayNameMap = {
      "zh_CN": AppLocalizations.of(context)!.chinese,
      "en_US": AppLocalizations.of(context)!.english
    };
    Map<String, Locale> localeMap = {
      "en_US": const Locale('en', 'US'),
      "zh_CN": const Locale('zh', 'CN')
    };
    String selectedItem = localeToDisplayNameMap[Intl.getCurrentLocale()]!;
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
          items: localeToDisplayNameMap.values.toList(),
          selectedItem: selectedItem,
          onChanged: (value) {
            setState(() {
              selectedItem = value!;
              String key = localeToDisplayNameMap.entries
                  .where((element) => element.value == selectedItem)
                  .first
                  .key;
              MyApp.setLocale(context, localeMap[key]!);
              locale = Intl.getCurrentLocale();
              _footButtonEnabled = isModified(locale, profileImage);
            });
          },
        ),
      ]),
    );
  }

  Row _getFootButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: ElevatedButton(
              onPressed: !_footButtonEnabled
                  ? null
                  : () {
                      var encodedImage = Base64Helper.encode(profileImage);
                      UploadImageRequest uploadImageRequest = UploadImageRequest(
                          resourceId: getIt<User>().id,
                          image: encodedImage,
                          type: ResourceType.USER);
                      getIt<ImageDao>()
                          .addImage(uploadImageRequest)
                          .then((imageResponse) {
                        setState(() {
                          // update user in memory
                          getIt<UserDao>()
                              .get(GetUserRequest(userId: getIt<User>().id))
                              .then((value) {
                            getIt.registerLazySingleton<User>(() => value!);
                          });
                          settingOriginalData.setProfileImage(
                              Base64Helper.decode(imageResponse!.image));
                          chosenImageName = "";
                          _footButtonEnabled = false;
                        });
                      });
                      // todo(yichi): update user locale here
                    },
              child: Text(AppLocalizations.of(context)!.submitForm)),
        ),
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
