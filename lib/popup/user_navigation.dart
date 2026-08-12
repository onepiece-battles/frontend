import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:one_piece_battles_flutter/components/chat_notifier.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import '../app_router.dart';
import '../constants/button_style.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class UserNavigation extends StatefulWidget {
  final BoxConstraints constraints;

  const UserNavigation({
    super.key,
    required BuildContext context,
    required this.constraints,
  });

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.constraints.maxWidth > 1500 ? 70.0 : 60.0;
    return InkWell(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () => showPopover(
        width: 160,
        arrowDxOffset: 3,
        direction: PopoverDirection.right,
        context: context,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 35,
              child: ElevatedButton(
                onPressed: () {
                  if (getIt<User>().loginRole == UserRole.VISITOR) {
                    context.go(AppRouter.registerPath);
                  } else {
                    context.goNamed('userProfile',
                        extra: getIt<User>().id,
                        pathParameters: {'name': getIt<User>().nickname});
                    Navigator.pop(context);
                  }
                },
                style: OnepieceButtonStyle.getDefaultStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ImageHelper.getSvgIconWithColor(
                        'images/svgs/profile.svg', 20, 15, Colors.white),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.userProfile,
                        style: OnepieceFonts.smallContentStyleWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 160,
              height: 35,
              child: ElevatedButton(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  final navigator = Navigator.of(context);
                  // Capture before the async gap (context is unsafe after).
                  final chatNotifier = context.read<ChatNotifier>();
                  try {
                    await getIt<UserDao>()
                        .logout(LogoutRequest(userId: getIt<User>().id));
                  } catch (_) {}
                  getIt<WebSocketService>().disconnect();
                  // Drop the remembered chat/scroll so the next login starts
                  // fresh on the first chat and nothing leaks across users.
                  chatNotifier.clearChatViewState();
                  if (getIt.isRegistered<User>()) {
                    getIt.unregister<User>();
                  }
                  getIt.registerLazySingleton<User>(
                      () => User(id: "", username: "", nickname: ""));
                  // Close popover before navigating to avoid overlay
                  // GlobalKey collisions during ShellRoute teardown.
                  navigator.pop();
                  router.replace(AppRouter.loginPath);
                },
                style: OnepieceButtonStyle.getDefaultStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.logout,
                        style: OnepieceFonts.smallContentStyleWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      child: ImageLazyLoader(
        uriProvider: () => getIt<User>().imageUri ?? '',
        width: avatarSize,
        borderWidth: 3,
        borderRadios: avatarSize,
      ),
    );
  }
}
