import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../main.dart';
import '../repository/user_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/compare_uint8list.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _emailSettingController =
      TextEditingController(text: getIt<User>().email);
  bool _emailSettingEnabled = false;
  final TextEditingController _nameController =
      TextEditingController(text: getIt<User>().name);
  bool _nameSettingEnabled = false;
  final SettingPageModel _originalData = SettingPageModel();
  final SettingPageModel _realtimeData = SettingPageModel();
  bool _footButtonEnabled = false;
  String _chosenImageName = "";
  @override
  void initState() {
    super.initState();
    _originalData.setCurrentLocale(getIt<Locale>());
    _originalData
        .setProfileImage(Base64Helper.decode(getIt<User>().profileImage!));
    _originalData.setEmail(getIt<User>().email!);
    _originalData.setName(getIt<User>().name);
    _realtimeData.setCurrentLocale(getIt<Locale>());
    _realtimeData
        .setProfileImage(Base64Helper.decode(getIt<User>().profileImage!));
    _realtimeData.setEmail(getIt<User>().email!);
    _realtimeData.setName(getIt<User>().name);
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
        _getName(context),
        const Divider(
          height: 10,
          thickness: 1,
        ),
        _getEmail(context),
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
              icon: Image.memory(_realtimeData.profileImage),
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
                      onPressed: () async {
                        XFile? pickedImage =
                            await OnepieceImagePicker.pickWebImage();
                        Uint8List imageInByte =
                            await pickedImage!.readAsBytes();
                        _realtimeData.setProfileImage(imageInByte);
                        setState(() {
                          _footButtonEnabled = isModified();
                          if (CompareUint8List.equals(
                              _realtimeData.profileImage,
                              _originalData.profileImage)) {
                            _chosenImageName =
                                AppLocalizations.of(context)!.noFileChosen;
                          } else {
                            _chosenImageName = pickedImage.name;
                          }
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      _chosenImageName != ""
                          ? _chosenImageName
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

  Widget _getName(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
            child: Text(
              AppLocalizations.of(context)!.nickname,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                flex: 15,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (_originalData.name == value) {
                        _nameSettingEnabled = false;
                        _realtimeData.setName(value);
                        _footButtonEnabled = isModified();
                      }
                    });
                  },
                  enabled: _nameSettingEnabled,
                  controller: _nameController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                    enabledBorder: UnderlineInputBorder(),
                    disabledBorder: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.themeColor)),
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: SizedBox(
                    height: 40,
                    child: Tooltip(
                      message: _nameSettingEnabled
                          ? AppLocalizations.of(context)!.confirmHint
                          : AppLocalizations.of(context)!.editHint,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _nameSettingEnabled = !_nameSettingEnabled;
                            if (!_nameSettingEnabled) {
                              _realtimeData.setName(_nameController.text);
                              _footButtonEnabled = isModified();
                            }
                          });
                        },
                        child: _nameSettingEnabled
                            ? const Icon(Icons.check)
                            : const Icon(Icons.edit),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _getEmail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
            child: Text(
              AppLocalizations.of(context)!.emailSetting,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                flex: 15,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (_originalData.email == value) {
                        _emailSettingEnabled = false;
                        _realtimeData.setEmail(value);
                        _footButtonEnabled = isModified();
                      }
                    });
                  },
                  enabled: _emailSettingEnabled,
                  controller: _emailSettingController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                    enabledBorder: UnderlineInputBorder(),
                    disabledBorder: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.themeColor)),
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: SizedBox(
                    height: 40,
                    child: Tooltip(
                      message: _emailSettingEnabled
                          ? AppLocalizations.of(context)!.confirmHint
                          : AppLocalizations.of(context)!.editHint,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _emailSettingEnabled = !_emailSettingEnabled;
                            if (!_emailSettingEnabled) {
                              _realtimeData
                                  .setEmail(_emailSettingController.text);
                              _footButtonEnabled = isModified();
                            }
                          });
                        },
                        child: _emailSettingEnabled
                            ? const Icon(Icons.check)
                            : const Icon(Icons.edit),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _getLocalization(BuildContext context) {
    Map<String, Locale> nameToLocale = {
      AppLocalizations.of(context)!.chinese: const Locale('zh', 'CN'),
      AppLocalizations.of(context)!.english: const Locale('en', 'US')
    };
    Map<Locale, String> localeToName = {
      const Locale('zh', 'CN'): AppLocalizations.of(context)!.chinese,
      const Locale('en', 'US'): AppLocalizations.of(context)!.english
    };
    String selectedItem = localeToName[getIt<Locale>()]!;
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
          items: nameToLocale.keys.toList(),
          selectedItem: selectedItem,
          onChanged: (value) {
            setState(() {
              Locale locale = nameToLocale[value]!;
              _realtimeData.setCurrentLocale(locale);
              _footButtonEnabled = isModified();
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
                    _realtimeData.setCurrentLocale(_originalData.locale);
                    _realtimeData.setProfileImage(_originalData.profileImage);
                    _realtimeData.setEmail(_originalData.email);
                    _realtimeData.setName(_originalData.name);
                    _footButtonEnabled = false;
                  });
                },
          child: Text(AppLocalizations.of(context)!.cancelPopUp),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: ElevatedButton(
              onPressed: !_footButtonEnabled
                  ? null
                  : () async {
                      // when this button is clicked, there are several things should be done:
                      // 1. update user profile image if necessary.
                      // 2. update user basic information: locale, email, name information if necessary.
                      var encodedImage =
                          Base64Helper.encode(_realtimeData.profileImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: getIt<User>().id,
                              image: encodedImage,
                              type: ResourceType.USER);
                      var getImageResponse =
                          await getIt<ImageDao>().addImage(uploadImageRequest);
                      _originalData.setProfileImage(
                          Base64Helper.decode(getImageResponse!.image));
                      UpdateUserRequest updateUserRequest = UpdateUserRequest(
                          locale: _realtimeData.locale.languageCode == 'en'
                              ? OnepieceLocale.enUS
                              : OnepieceLocale.zhCN,
                          name: _realtimeData.name,
                          email: _realtimeData.email,
                          id: getIt<User>().id);
                      var updateUserResponse =
                          await getIt<UserDao>().updateUser(updateUserRequest);
                      getIt.registerLazySingleton<User>(
                          () => updateUserResponse!.user!);
                      setState(() {
                        _chosenImageName = "";
                        _emailSettingEnabled = false;
                        _nameSettingEnabled = false;
                        _footButtonEnabled = false;
                        MyApp.setLocale(context, _realtimeData._locale);
                        _originalData.copy(_realtimeData);
                      });
                    },
              child: Text(AppLocalizations.of(context)!.submitForm)),
        ),
      ],
    );
  }

  bool isModified() {
    return _originalData != _realtimeData &&
        !_emailSettingEnabled &&
        !_nameSettingEnabled;
  }
}

class SettingPageModel {
  late Uint8List _profileImage;
  late Locale _locale;
  late String _email;
  late String _name;

  void copy(SettingPageModel model) {
    setProfileImage(model.profileImage);
    setCurrentLocale(model.locale);
    setName(model.name);
    setEmail(model.email);
  }

  void setProfileImage(Uint8List profileImage) {
    _profileImage = profileImage;
  }

  void setCurrentLocale(Locale locale) {
    _locale = locale;
  }

  void setEmail(String email) {
    _email = email;
  }

  void setName(String name) {
    _name = name;
  }

  Locale get locale => _locale;
  Uint8List get profileImage => _profileImage;
  String get email => _email;
  String get name => _name;

  @override
  bool operator ==(Object other) {
    if (other is! SettingPageModel) {
      return false;
    }
    if (locale != other.locale) {
      return false;
    }
    if (email != other.email) {
      return false;
    }
    if (name != other.name) {
      return false;
    }
    if (!CompareUint8List.equals(profileImage, other.profileImage)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      locale.hashCode + profileImage.hashCode + email.hashCode + name.hashCode;
}
