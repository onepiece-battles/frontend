import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';

// Assuming these imports exist based on your original code
import '../../l10n/app_localizations.dart';
import '../../config/resource_permission_manager.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../popup/email_verification.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/image_dao.dart';
import '../../repository/user_dao.dart';
import '../../repository/email_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';

// --- 1. STATE MODEL ---
// Holds the data for the screen. Immutable style preferred for safety.
class UserProfileFormData {
  final Uint8List? profileImage;
  final String nickname;
  final String username; // email
  final String? imageName;

  UserProfileFormData({
    this.profileImage,
    required this.nickname,
    required this.username,
    this.imageName,
  });

  // Helper to create copy for edits
  UserProfileFormData copyWith({
    Uint8List? profileImage,
    String? nickname,
    String? username,
    String? imageName,
  }) {
    return UserProfileFormData(
      profileImage: profileImage ?? this.profileImage,
      nickname: nickname ?? this.nickname,
      username: username ?? this.username,
      imageName: imageName ?? this.imageName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserProfileFormData &&
              runtimeType == other.runtimeType &&
              listEquals(profileImage, other.profileImage) && // Use flutter/foundation
              nickname == other.nickname &&
              username == other.username;

  @override
  int get hashCode => Object.hash(nickname, username, profileImage);
}

// --- 2. CONTROLLER (LOGIC) ---
// Handles API calls, validation, and updates the UI.
class UserProfileController extends ChangeNotifier {
  final String userId;
  final UserDao _userDao = GetIt.I<UserDao>();
  final ImageDao _imageDao = GetIt.I<ImageDao>();
  final EmailDao _emailDao = GetIt.I<EmailDao>();

  bool isLoading = true;
  bool isSaving = false;

  late User _currentUser;
  late UserProfileFormData _originalData;
  late UserProfileFormData _currentData;

  // Getters for UI
  UserProfileFormData get data => _currentData;
  User get user => _currentUser; // For specific ID access
  bool get hasChanges => _originalData != _currentData;
  bool get isEmailVerified => _currentUser.emailVerified ?? false;

  UserProfileController(this.userId) {
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _userDao.get(GetUserRequest(userId: userId));
      _currentUser = response!;

      final imageBytes = Base64Helper.decode(GetIt.I<User>().profileImage ?? "");

      _originalData = UserProfileFormData(
        profileImage: imageBytes,
        nickname: _currentUser.nickname,
        username: _currentUser.username,
      );

      _currentData = _originalData.copyWith();
    } catch (e) {
      // Handle Error (Log it or show toast)
      debugPrint("Error loading profile: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateNickname(String newNickname) {
    _currentData = _currentData.copyWith(nickname: newNickname);
    notifyListeners();
  }

  void resetChanges() {
    _currentData = _originalData.copyWith();
    notifyListeners();
  }

  Future<void> pickImage(BuildContext context) async {
    final XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
    if (pickedImage == null) return;

    final Uint8List imageInByte = await pickedImage.readAsBytes();

    // Validation
    if (!ImageHelper.isValidImageSize(500 * 1024, imageInByte)) {
      OnepieceAlert.getBasicAlertDialogFunc(
          context,
          AppLocalizations.of(context)!.alert,
          AppLocalizations.of(context)!.imageSizeExceedsLimit);
      return;
    }

    _currentData = _currentData.copyWith(
      profileImage: imageInByte,
      imageName: pickedImage.name,
    );
    notifyListeners();
  }

  Future<void> sendVerificationEmail(BuildContext context) async {
    await _emailDao.verifyEmailAddress(
        VerifyEmailAddressRequest(id: _currentUser.id, email: _currentUser.username)
    );

    if (context.mounted) {
      showCupertinoModalPopup(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        context: context,
        builder: (_) => Dialog(
          child: EmailVerification(userId: _currentUser.id, email: _currentUser.username),
        ),
      );
    }
  }

  Future<void> saveProfile(BuildContext context) async {
    if (!hasChanges) return;

    isSaving = true;
    notifyListeners();

    try {
      // 1. Upload Image (only if a new image has been selected)
      if (_currentData.profileImage != null) {
        final encodedImage = Base64Helper.encode(_currentData.profileImage!);
        await _imageDao.addImage(UploadImageRequest(
          resourceId: GetIt.I<User>().id,
          image: encodedImage,
          type: ResourceType.USER,
        ));
      }

      // 2. Update User Data
      final response = await _userDao.updateUser(UpdateUserRequest(
        locale: OnepieceLocale.zhCN,
        nickname: _currentData.nickname.trim(),
        id: GetIt.I<User>().id,
      ));

      // 3. Update Cache & Router
      ResourcePermissionManager.updateUserCache(response!.user!);

      if (context.mounted) {
        context.goNamed('userProfile',
            extra: GetIt.I<User>().id,
            pathParameters: {'name': GetIt.I<User>().nickname});
      }

      // Update internal state to match new saved state
      _originalData = _currentData.copyWith();
    } catch (e) {
      debugPrint("Error saving: $e");
      OnepieceAlert.getBasicAlertDialogFunc(context, "Error", "Failed to save profile");
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

// --- 3. MAIN WIDGET ---
class UserProfile extends StatefulWidget {
  final String userId;
  const UserProfile({super.key, required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late UserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserProfileController(widget.userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _AvatarSection(controller: _controller),
              const Divider(height: 10, thickness: 1),
              _NicknameSection(controller: _controller),
              const Divider(height: 10, thickness: 1),
              _EmailSection(controller: _controller),
              const Divider(height: 10, thickness: 1),
              _ActionButtons(controller: _controller),
            ],
          ),
        );
      },
    );
  }
}

// --- 4. SUB-COMPONENTS (Clean UI) ---

class _AvatarSection extends StatelessWidget {
  final UserProfileController controller;
  const _AvatarSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.avatarHeader, style: OnepieceFonts.headerStyle),
          const SizedBox(height: 10),
          Text(loc.avatarHeaderDescription, style: OnepieceFonts.contentStyle),
          const SizedBox(height: 10),
          Row(
            children: [
              ImageHelper.getRoundImageFrame(
                  100, 100, 3,
                  OnepieceColors.liteFancyBlue,
                  100,
                  controller.data.profileImage!
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.uploadNewAvatar,
                    style: OnepieceFonts.contentStyle,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: () => controller.pickImage(context),
                        child: Text(loc.chooseFile),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        controller.data.imageName ?? loc.noFileChosen,
                        style: OnepieceFonts.contentStyle,
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(loc.maxFileSize500, style: OnepieceFonts.contentStyle)
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _NicknameSection extends StatefulWidget {
  final UserProfileController controller;
  const _NicknameSection({required this.controller});

  @override
  State<_NicknameSection> createState() => _NicknameSectionState();
}

class _NicknameSectionState extends State<_NicknameSection> {
  final TextEditingController _textController = TextEditingController();
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.data.nickname;
  }

  @override
  void didUpdateWidget(covariant _NicknameSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text field if external change happened (e.g. reset)
    if (_textController.text != widget.controller.data.nickname && !_isEditable) {
      _textController.text = widget.controller.data.nickname;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              AppLocalizations.of(context)!.nickname,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: _textController,
                  enabled: _isEditable,
                  onChanged: (val) => widget.controller.updateNickname(val),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(left: 10),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isEditable = !_isEditable;
                    if(!_isEditable) {
                      // Ensure data is synced when closing edit
                      _textController.text = widget.controller.data.nickname;
                    }
                  });
                },
                child: SizedBox(
                  width: 25, height: 25,
                  child: ImageHelper.getSvgIconWithColor(
                      _isEditable ? 'images/svgs/check.svg' : 'images/svgs/edit.svg',
                      150, 150, OnepieceColors.fancyBlue
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailSection extends StatelessWidget {
  final UserProfileController controller;
  const _EmailSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isVerified = controller.isEmailVerified;

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                Text(loc.email, style: OnepieceFonts.headerStyle),
                const SizedBox(width: 10),
                Tooltip(
                  message: isVerified ? loc.verified : loc.notVerified,
                  child: SizedBox(
                    width: 30, height: 30,
                    child: ImageHelper.getSvgIconWithColor(
                      isVerified ? 'images/svgs/check-circle.svg' : 'images/svgs/alert.svg',
                      150, 150,
                      isVerified ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  controller.data.username,
                  style: OnepieceFonts.contentStyle,
                ),
              ),
              if (!isVerified)
                ElevatedButton(
                  onPressed: () => controller.sendVerificationEmail(context),
                  child: Text(loc.sendEmail),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final UserProfileController controller;
  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: controller.hasChanges
                ? () => controller.resetChanges()
                : null,
            child: Text(loc.cancelPopUp),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: (controller.hasChanges && !controller.isSaving)
                ? () => controller.saveProfile(context)
                : null,
            child: controller.isSaving
                ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)
            )
                : Text(loc.submitForm),
          ),
        ],
      ),
    );
  }
}
