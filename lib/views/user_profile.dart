import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';
import '../config/resource_permission_manager.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../popup/email_verification.dart';
import '../repository/image_dao.dart';
import '../repository/user_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/compare_uint8list.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class UserProfile extends StatefulWidget {
  final String userId;
  const UserProfile({super.key, required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late User user;
  final UserProfileModel _originalData = UserProfileModel();
  final UserProfileModel _realtimeData = UserProfileModel();
  String _chosenImageName = "";
  final ValueNotifier<bool> _nicknameEditable = ValueNotifier(false);
  final ValueNotifier<bool> _dataModified = ValueNotifier(false);
  bool _emailVerified = false;

  _loadData() {
    return getIt<UserDao>().get(GetUserRequest(userId: widget.userId));
  }

  _prepareData(User user) {
    this.user = user;
    _nicknameController.text = user.nickname;
    _emailController.text = user.username;
    _emailVerified = user.emailVerified!;
    _originalData
        .setProfileImage(Base64Helper.decode(getIt<User>().profileImage!));
    _originalData.setUsername(getIt<User>().username);
    _originalData.setNickname(getIt<User>().nickname);
    _realtimeData
        .setProfileImage(Base64Helper.decode(getIt<User>().profileImage!));
    _realtimeData.setUsername(getIt<User>().username);
    _realtimeData.setNickname(getIt<User>().nickname);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return SingleChildScrollView(
              child: Column(
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
              _getFootButtons(context)
            ],
          ));
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
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      onPressed: () async {
                        XFile? pickedImage =
                            await OnepieceImagePicker.pickWebImage();
                        Uint8List imageInByte =
                            await pickedImage!.readAsBytes();
                        _realtimeData.setProfileImage(imageInByte);
                        setState(() {
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
          ValueListenableBuilder(
              valueListenable: _nicknameEditable,
              builder: (context, value, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        onChanged: (value) {
                          _realtimeData.setNickname(value);
                          _dataModified.value = _checkModified();
                          if (_originalData.nickname == value) {
                            _nicknameEditable.value = false;
                          }
                        },
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0)),
                        enabled: _nicknameEditable.value,
                        controller: _nicknameController,
                      ),
                    ),
                    InkWell(
                      hoverColor: Colors.white,
                      onTap: () {
                        _nicknameEditable.value = !_nicknameEditable.value;
                      },
                      child: SizedBox(
                          width: 25,
                          height: 25,
                          child: !_nicknameEditable.value
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
                  ],
                );
              }),
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
              AppLocalizations.of(context)!.email,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 300,
                child: TextFormField(
                  onChanged: null,
                  controller: _emailController,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0)),
                  enabled: false,
                ),
              ),
              Tooltip(
                message: _emailVerified
                    ? AppLocalizations.of(context)!.verified
                    : AppLocalizations.of(context)!.notVerified,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: _emailVerified
                      ? ImageHelper.getSvgIconWithColor(
                          'images/svgs/check-circle.svg',
                          150,
                          150,
                          Colors.green)
                      : ImageHelper.getSvgIconWithColor(
                          'images/svgs/alert.svg', 150, 150, Colors.red),
                ),
              ),
              if (!_emailVerified)
                ElevatedButton(
                  style: OnepieceButtonStyle.getDefaultStyle(),
                  onPressed: () {
                    getIt<UserDao>()
                        .sendEmail(
                            SendEmailRequest(id: user.id, email: user.username))
                        .then((value) => {
                              showCupertinoModalPopup(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                context: context,
                                builder: ((context) {
                                  return Dialog(
                                    // backgroundColor: OnepieceColors.liteFancyBlue,
                                    alignment: AlignmentDirectional.center,
                                    child: EmailVerification(
                                        userId: user.id, email: user.username),
                                  );
                                }),
                              )
                            });
                  },
                  child: Text(AppLocalizations.of(context)!.sendEmail),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Row _getFootButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ValueListenableBuilder(
            valueListenable: _dataModified,
            builder: (context, value, _) {
              return ElevatedButton(
                style: OnepieceButtonStyle.getDefaultStyle(),
                onPressed: !_dataModified.value
                    ? null
                    : () {
                        setState(() {
                          _realtimeData
                              .setProfileImage(_originalData.profileImage);
                          _realtimeData.setUsername(_originalData.username);
                          _realtimeData.setNickname(_originalData.nickname);
                          _dataModified.value = false;
                          _nicknameEditable.value = false;
                        });
                      },
                child: Text(AppLocalizations.of(context)!.cancelPopUp),
              );
            }),
        ValueListenableBuilder(
            valueListenable: _dataModified,
            builder: (context, value, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: ElevatedButton(
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    onPressed: !_dataModified.value
                        ? null
                        : () async {
                            submitData(context).then((value) => {
                                  ResourcePermissionManager.updateUserCache(
                                      value!),
                                  context.goNamed('userProfile',
                                      extra: getIt<User>().id,
                                      pathParameters: {
                                        'name': getIt<User>().nickname
                                      })
                                });
                          },
                    child: Text(AppLocalizations.of(context)!.submitForm)),
              );
            }),
      ],
    );
  }

  Future<User?> submitData(BuildContext context) async {
    var encodedImage = Base64Helper.encode(_realtimeData.profileImage);
    UploadImageRequest uploadImageRequest = UploadImageRequest(
        resourceId: getIt<User>().id,
        image: encodedImage,
        type: ResourceType.USER);
    await getIt<ImageDao>().addImage(uploadImageRequest);
    UpdateUserRequest updateUserRequest = UpdateUserRequest(
        locale: OnepieceLocale.zhCN,
        nickname: _realtimeData.nickname.trim(),
        id: getIt<User>().id);
    var response = await getIt<UserDao>().updateUser(updateUserRequest);
    return response?.user;
  }

  bool _checkModified() {
    return _dataModified.value = _originalData != _realtimeData;
  }
}

class UserProfileModel {
  late Uint8List _profileImage;
  // the _username is email
  late String _username;
  late String _nickname;

  void copy(UserProfileModel model) {
    setProfileImage(model.profileImage);
    setNickname(model.nickname);
    setUsername(model.username);
  }

  void setProfileImage(Uint8List profileImage) {
    _profileImage = profileImage;
  }

  void setUsername(String username) {
    _username = username;
  }

  void setNickname(String nickname) {
    _nickname = nickname;
  }

  Uint8List get profileImage => _profileImage;
  String get username => _username;
  String get nickname => _nickname;

  @override
  bool operator ==(Object other) {
    if (other is! UserProfileModel) {
      return false;
    }
    if (username != other.username) {
      return false;
    }
    if (nickname != other.nickname) {
      return false;
    }
    if (!CompareUint8List.equals(profileImage, other.profileImage)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      profileImage.hashCode + username.hashCode + nickname.hashCode;
}
