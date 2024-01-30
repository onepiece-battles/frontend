import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_fonts.dart';
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
  late User user;
  final UserProfileModel _originalData = UserProfileModel();
  final UserProfileModel _realtimeData = UserProfileModel();
  String _chosenImageName = "";

  _loadData() {
    return getIt<UserDao>().get(GetUserRequest(userId: widget.userId));
  }

  _prepareData(User user) {
    this.user = user;
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
