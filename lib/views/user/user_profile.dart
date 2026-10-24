import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../../utils/responsive_breakpoints.dart';

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
          listEquals(
              profileImage, other.profileImage) && // Use flutter/foundation
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
  bool isSavingAvatar = false;
  bool isSavingNickname = false;
  bool isSendingVerificationEmail = false;

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

      final imageBytes =
          Base64Helper.decode(GetIt.I<User>().profileImage ?? "");

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

  Future<void> pickImage(BuildContext context) async {
    final alertTitle = AppLocalizations.of(context)!.alert;
    final alertMsg = AppLocalizations.of(context)!.imageSizeExceedsLimit;
    final showAlert = OnepieceAlert.createAlertShower(context);

    final XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
    if (pickedImage == null) return;

    final Uint8List imageInByte = await pickedImage.readAsBytes();

    // Validation
    if (!ImageHelper.isValidImageSize(500 * 1024, imageInByte)) {
      showAlert(alertTitle, alertMsg);
      return;
    }

    final previousData = _currentData;
    _currentData = _currentData.copyWith(
      profileImage: imageInByte,
      imageName: pickedImage.name,
    );
    isSavingAvatar = true;
    notifyListeners();

    try {
      final encodedImage = Base64Helper.encode(imageInByte);
      await _imageDao.addImage(UploadImageRequest(
        resourceId: GetIt.I<User>().id,
        image: encodedImage,
        type: ResourceType.USER,
      ));

      final refreshedUser =
          await _userDao.get(GetUserRequest(userId: GetIt.I<User>().id));
      if (refreshedUser != null) {
        refreshedUser.profileImage ??= encodedImage;
        _currentUser = refreshedUser;
        ResourcePermissionManager.updateUserCache(refreshedUser);
      }

      _currentData = UserProfileFormData(
        profileImage: imageInByte,
        nickname: _currentUser.nickname,
        username: _currentUser.username,
      );
      _originalData = _currentData.copyWith();
    } catch (e) {
      debugPrint("Error saving avatar: $e");
      _currentData = previousData;
      if (context.mounted) {
        OnepieceAlert.getBasicAlertDialogFunc(
            context, "Error", "Failed to save avatar");
      }
    } finally {
      isSavingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail(BuildContext context) async {
    isSendingVerificationEmail = true;
    notifyListeners();

    try {
      await _emailDao.verifyEmailAddress(VerifyEmailAddressRequest(
          id: _currentUser.id, email: _currentUser.username));

      if (!context.mounted) return;

      final verified = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.18),
        builder: (_) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: EmailVerification(
            userId: _currentUser.id,
            email: _currentUser.username,
          ),
        ),
      );

      if (verified == true) {
        final refreshedUser =
            await _userDao.get(GetUserRequest(userId: _currentUser.id));
        if (refreshedUser != null) {
          _currentUser = refreshedUser;
          ResourcePermissionManager.updateUserCache(refreshedUser);
        }
      }
    } catch (e) {
      debugPrint("Error sending verification email: $e");
      if (context.mounted) {
        OnepieceAlert.getBasicAlertDialogFunc(
            context, "Error", "Failed to send verification email");
      }
    } finally {
      isSendingVerificationEmail = false;
      notifyListeners();
    }
  }

  Future<bool> saveNickname(BuildContext context, String nickname) async {
    final trimmedNickname = nickname.trim();
    if (trimmedNickname == _originalData.nickname) {
      _currentData = _originalData.copyWith();
      notifyListeners();
      return true;
    }

    final previousData = _currentData;
    final previousProfileImage = _currentUser.profileImage;
    final previousImageUri = _currentUser.imageUri;
    _currentData = _currentData.copyWith(nickname: trimmedNickname);
    isSavingNickname = true;
    notifyListeners();

    // Capture router before async gap to avoid lint warnings
    final router = GoRouter.of(context);

    try {
      final response = await _userDao.updateUser(UpdateUserRequest(
        locale: OnepieceLocale.zhCN,
        nickname: trimmedNickname,
        id: GetIt.I<User>().id,
      ));

      final updatedUser = response!.user!;
      if (updatedUser.profileImage == null || updatedUser.profileImage == "") {
        updatedUser.profileImage = previousProfileImage;
      }
      if (updatedUser.imageUri == null || updatedUser.imageUri == "") {
        updatedUser.imageUri = previousImageUri;
      }

      ResourcePermissionManager.updateUserCache(updatedUser);
      _currentUser = updatedUser;
      _currentData = UserProfileFormData(
        profileImage: _currentUser.profileImage == null
            ? previousData.profileImage
            : Base64Helper.decode(_currentUser.profileImage!),
        nickname: _currentUser.nickname,
        username: _currentUser.username,
      );
      _originalData = _currentData.copyWith();

      if (context.mounted) {
        router.goNamed('userProfile',
            extra: GetIt.I<User>().id,
            pathParameters: {'name': GetIt.I<User>().nickname});
      }
    } catch (e) {
      debugPrint("Error saving nickname: $e");
      _currentData = previousData;
      if (context.mounted) {
        OnepieceAlert.getBasicAlertDialogFunc(
            context, "Error", "Failed to save nickname");
      }
      return false;
    } finally {
      isSavingNickname = false;
      notifyListeners();
    }
    return true;
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow =
                ResponsiveBreakpoints.isMobileFromConstraints(constraints);
            return SingleChildScrollView(
              padding:
                  isNarrow ? const EdgeInsets.fromLTRB(12, 12, 12, 20) : null,
              child: Column(
                children: [
                  _AvatarSection(controller: _controller),
                  const SizedBox(height: 12),
                  _NicknameSection(controller: _controller),
                  const SizedBox(height: 12),
                  _EmailSection(controller: _controller),
                ],
              ),
            );
          },
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.avatarHeader,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ImageHelper.getRoundImageFrame(
                      80,
                      80,
                      3,
                      OnepieceColors.liteFancyBlue,
                      80,
                      controller.data.profileImage!),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.uploadNewAvatar,
                          style: OnepieceFonts.contentStyle),
                      const SizedBox(height: 8),
                      SizedBox(
                          height: 32,
                          child: ElevatedButton(
                              style: OnepieceButtonStyle.getDefaultStyle(),
                              onPressed: controller.isSavingAvatar
                                  ? null
                                  : () => controller.pickImage(context),
                              child: controller.isSavingAvatar
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text(loc.chooseFile,
                                      style: const TextStyle(fontSize: 13)))),
                      const SizedBox(height: 4),
                      Text(controller.data.imageName ?? loc.noFileChosen,
                          style: OnepieceFonts.smallContentStyle),
                      const SizedBox(height: 4),
                      Text(loc.maxFileSize500,
                          style: OnepieceFonts.smallContentStyle),
                    ],
                  ))
                ],
              ),
            ],
          )),
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

  Future<void> _confirmNickname() async {
    final saved =
        await widget.controller.saveNickname(context, _textController.text);
    if (mounted && saved) {
      setState(() {
        _isEditable = false;
        _textController.text = widget.controller.data.nickname;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.data.nickname;
  }

  @override
  void didUpdateWidget(covariant _NicknameSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text field if external change happened (e.g. reset)
    if (_textController.text != widget.controller.data.nickname &&
        !_isEditable) {
      _textController.text = widget.controller.data.nickname;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(AppLocalizations.of(context)!.nickname,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const Spacer(),
              InkWell(
                onTap: widget.controller.isSavingNickname
                    ? null
                    : () {
                        if (_isEditable) {
                          _confirmNickname();
                          return;
                        }

                        setState(() {
                          _isEditable = true;
                        });
                      },
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: widget.controller.isSavingNickname
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : ImageHelper.getSvgIconWithColor(
                            _isEditable
                                ? 'images/svgs/check.svg'
                                : 'images/svgs/edit.svg',
                            150,
                            150,
                            OnepieceColors.fancyBlue)),
              ),
            ]),
            const SizedBox(height: 10),
            _isEditable
                ? SizedBox(
                    height: 35,
                    child: TextFormField(
                      controller: _textController,
                      onChanged: (val) => widget.controller.updateNickname(val),
                      decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: OnepieceColors.separator)),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: OnepieceColors.separator)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: OnepieceColors.fancyGreen,
                                  width: 1.5)),
                          labelStyle: OnepieceFonts.dropDownItemStyle),
                    ))
                : Text(widget.controller.data.nickname,
                    style: OnepieceFonts.contentStyle
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
          ])),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(loc.email,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const SizedBox(width: 8),
              Tooltip(
                message: isVerified ? loc.verified : loc.notVerified,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: ImageHelper.getSvgIconWithColor(
                      isVerified
                          ? 'images/svgs/check-circle.svg'
                          : 'images/svgs/alert.svg',
                      150,
                      150,
                      isVerified ? Colors.green : Colors.red),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text(
                  controller.data.username,
                  style: OnepieceFonts.contentStyle
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isVerified) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    onPressed: controller.isSendingVerificationEmail
                        ? null
                        : () => controller.sendVerificationEmail(context),
                    icon: controller.isSendingVerificationEmail
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_unread_outlined,
                            size: 16),
                    label: Text(loc.sendEmail,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ]),
          ])),
    );
  }
}
