import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';

import '../app_router.dart';
import '../constants/button_style.dart';
import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPopover(
        width: 140,
        height: 70,
        arrowDxOffset: 3,
        direction: PopoverDirection.right,
        context: context,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (context) => Column(
          children: [
            SizedBox(
                width: 140,
                height: 35,
                child: ElevatedButton(
                  onPressed: () {},
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
                )),
            // const Divider(color: Colors.white),
            SizedBox(
                width: 140,
                height: 35,
                child: ElevatedButton(
                  onPressed: () {
                    getIt<UserDao>()
                        .logout(LogoutRequest(userId: getIt<User>().id));
                    getIt.registerLazySingleton<User>(() => User(id: "", username: "", nickname: ""));
                    context.go(AppRouter.loginPath);
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
                )),
          ],
        ),
      ),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          border: Border.all(
              color: Colors.grey, width: 2, style: BorderStyle.solid),
        ),
        child: FittedBox(
          fit: BoxFit.fill,
          child: Image.memory(Base64Helper.decode(getIt<User>().profileImage!)),
        ),
      ),
    );
  }
}
