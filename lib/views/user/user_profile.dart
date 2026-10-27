import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';

// Assuming these imports exist based on your original code
import '../../l10n/app_localizations.dart';
import '../../config/resource_permission_manager.dart';
import '../../constants/onepiece_colors.dart';
import '../../popup/email_verification.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/image_dao.dart';
import '../../repository/user_dao.dart';
import '../../repository/email_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/i18n_helper.dart';
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
  bool hasLoadError = false;
  bool isSavingAvatar = false;
  bool isSavingNickname = false;
  bool isSendingVerificationEmail = false;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  late User _currentUser;
  late UserProfileFormData _originalData;
  late UserProfileFormData _currentData;

  // Getters for UI
  UserProfileFormData get data => _currentData;
  User get user => _currentUser; // For specific ID access
  bool get hasChanges => _originalData != _currentData;
  bool get isEmailVerified => _currentUser.emailVerified ?? false;

  UserProfileController(this.userId) {
    reload();
  }

  Future<void> reload() async {
    isLoading = true;
    hasLoadError = false;
    notifyListeners();

    try {
      final response = await _userDao.get(GetUserRequest(userId: userId));
      if (response == null) throw StateError('Profile unavailable');
      _currentUser = response;

      final imageSource = response.profileImage?.isNotEmpty == true
          ? response.profileImage!
          : (GetIt.I<User>().profileImage ?? '');
      final imageBytes = Base64Helper.decode(imageSource);

      _originalData = UserProfileFormData(
        profileImage: imageBytes,
        nickname: _currentUser.nickname,
        username: _currentUser.username,
      );

      _currentData = _originalData.copyWith();
    } catch (e) {
      hasLoadError = true;
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
            context,
            AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.saveAvatarFailed);
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
            context,
            AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.sendVerificationEmailFailed);
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
        locale:
            I18nHelper.convertToOnepieceLocale(Localizations.localeOf(context)),
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
        router.goNamed('user_profile',
            extra: GetIt.I<User>().id,
            pathParameters: {'name': GetIt.I<User>().nickname});
      }
    } catch (e) {
      debugPrint("Error saving nickname: $e");
      _currentData = previousData;
      if (context.mounted) {
        OnepieceAlert.getBasicAlertDialogFunc(
            context,
            AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.saveNicknameFailed);
      }
      return false;
    } finally {
      isSavingNickname = false;
      notifyListeners();
    }
    return true;
  }
}

// --- Account page ---
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
  void didUpdateWidget(covariant UserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _controller.dispose();
      _controller = UserProfileController(widget.userId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: OnepieceColors.surface,
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  narrow ? 16 : 32, narrow ? 22 : 36, narrow ? 16 : 32, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _controller.isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _controller.hasLoadError
                          ? _ProfileError(
                              message: loc.profileLoadFailed,
                              retryLabel: loc.retryLoading,
                              onRetry: _controller.reload,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.myAccount,
                                    style: TextStyle(
                                        fontSize: narrow ? 25 : 30,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.6,
                                        color: OnepieceColors.primaryLabel)),
                                const SizedBox(height: 22),
                                _ProfileHero(
                                    controller: _controller, narrow: narrow),
                                const SizedBox(height: 28),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, bottom: 10),
                                  child: Text(loc.basicInfo,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: OnepieceColors.primaryLabel)),
                                ),
                                _ProfileInfoCard(controller: _controller),
                              ],
                            ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  const _ProfileError(
      {required this.message, required this.retryLabel, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            const Icon(Icons.person_off_outlined,
                size: 40, color: OnepieceColors.secondaryLabel),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: OnepieceColors.secondaryLabel)),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ]),
        ),
      );
}

class _ProfileSurface extends StatelessWidget {
  final Widget child;
  const _ProfileSurface({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: OnepieceColors.separator, width: .8),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _ProfileHero extends StatelessWidget {
  final UserProfileController controller;
  final bool narrow;
  const _ProfileHero({required this.controller, required this.narrow});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bytes = controller.data.profileImage;
    final avatar = ClipOval(
      child: SizedBox(
        width: 86,
        height: 86,
        child: bytes == null || bytes.isEmpty
            ? const ColoredBox(
                color: OnepieceColors.surface,
                child: Icon(Icons.person_outline,
                    size: 42, color: OnepieceColors.secondaryLabel),
              )
            : ImageHelper.rasterImage(bytes, fit: BoxFit.cover),
      ),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(controller.data.nickname,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: OnepieceColors.primaryLabel)),
        const SizedBox(height: 5),
        Text(controller.data.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: OnepieceColors.secondaryLabel)),
        const SizedBox(height: 10),
        _VerificationBadge(verified: controller.isEmailVerified),
      ],
    );
    final upload = OutlinedButton.icon(
      onPressed: controller.isSavingAvatar
          ? null
          : () => controller.pickImage(context),
      icon: controller.isSavingAvatar
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.camera_alt_outlined, size: 17),
      label: Text(loc.uploadNewAvatar),
      style: OutlinedButton.styleFrom(
        foregroundColor: OnepieceColors.fancyBlue,
        side: const BorderSide(color: OnepieceColors.separator),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
    return _ProfileSurface(
      child: Padding(
        padding: EdgeInsets.all(narrow ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              avatar,
              const SizedBox(width: 18),
              Expanded(child: identity),
              if (!narrow) ...[const SizedBox(width: 18), upload],
            ]),
            if (narrow) ...[
              const SizedBox(height: 18),
              upload,
            ],
            const SizedBox(height: 11),
            Text(loc.maxFileSize500,
                style: const TextStyle(
                    fontSize: 12, color: OnepieceColors.secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool verified;
  const _VerificationBadge({required this.verified});

  @override
  Widget build(BuildContext context) {
    final label = verified
        ? AppLocalizations.of(context)!.verified
        : AppLocalizations.of(context)!.notVerified;
    final color = verified ? const Color(0xFF287D57) : const Color(0xFF9A6830);
    final fill = verified ? const Color(0xFFE9F5EF) : const Color(0xFFFFF4E7);
    return DecoratedBox(
      decoration:
          BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(verified ? Icons.check_circle_outline : Icons.info_outline,
              size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final UserProfileController controller;
  const _ProfileInfoCard({required this.controller});

  @override
  Widget build(BuildContext context) => _ProfileSurface(
        child: Column(children: [
          _NicknameRow(controller: controller),
          const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: OnepieceColors.separator),
          _EmailRow(controller: controller),
        ]),
      );
}

class _NicknameRow extends StatefulWidget {
  final UserProfileController controller;
  const _NicknameRow({required this.controller});

  @override
  State<_NicknameRow> createState() => _NicknameRowState();
}

class _NicknameRowState extends State<_NicknameRow> {
  final _textController = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.data.nickname;
  }

  @override
  void didUpdateWidget(covariant _NicknameRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && _textController.text != widget.controller.data.nickname) {
      _textController.text = widget.controller.data.nickname;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_textController.text.trim().isEmpty) return;
    final saved = await widget.controller
        .saveNickname(context, _textController.text.trim());
    if (mounted && saved) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(loc.nickname,
                style: const TextStyle(
                    fontSize: 12, color: OnepieceColors.secondaryLabel)),
          ),
          if (!_editing)
            IconButton(
              tooltip: loc.profileEditNickname,
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: OnepieceColors.fancyBlue),
            ),
        ]),
        if (_editing) ...[
          const SizedBox(height: 7),
          TextField(
            controller: _textController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: OnepieceColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 11),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: widget.controller.isSavingNickname
                  ? null
                  : () => setState(() {
                        _editing = false;
                        _textController.text = widget.controller.data.nickname;
                      }),
              child: Text(loc.profileCancel),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: widget.controller.isSavingNickname ||
                      _textController.text.trim().isEmpty
                  ? null
                  : _save,
              style: FilledButton.styleFrom(
                backgroundColor: OnepieceColors.fancyBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.controller.isSavingNickname
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(loc.profileSave),
            ),
          ]),
        ] else ...[
          const SizedBox(height: 4),
          Text(widget.controller.data.nickname,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OnepieceColors.primaryLabel)),
        ],
      ]),
    );
  }
}

class _EmailRow extends StatelessWidget {
  final UserProfileController controller;
  const _EmailRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 19),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.email,
            style: const TextStyle(
                fontSize: 12, color: OnepieceColors.secondaryLabel)),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(
            child: Text(controller.data.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: OnepieceColors.primaryLabel)),
          ),
          if (!controller.isEmailVerified) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: controller.isSendingVerificationEmail
                  ? null
                  : () => controller.sendVerificationEmail(context),
              child: controller.isSendingVerificationEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.sendEmail),
            ),
          ],
        ]),
      ]),
    );
  }
}
