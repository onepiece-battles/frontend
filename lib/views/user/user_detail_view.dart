import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/onepiece_tag.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class UserDetailView extends StatefulWidget {
  final String userId;

  const UserDetailView({super.key, required this.userId});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  late User user;

  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<UserDao>().get(GetUserRequest(userId: widget.userId));
  }

  _prepareData(User user) {
    this.user = user;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getBasicInfo(context),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
                _getLoginStatus(context),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
              ],
            ),
          );
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

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(
      builder: (context, basicState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.basicInfo,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ImageHelper.getRoundImageFrame(
                  150,
                  150,
                  3,
                  OnepieceColors.liteFancyBlue,
                  150,
                  Base64Helper.decode(user.profileImage!)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
              child: Text(
                AppLocalizations.of(context)!.nickname,
                style: OnepieceFonts.contentStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
              child: Text(
                user.nickname,
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
              child: Text(
                AppLocalizations.of(context)!.email,
                style: OnepieceFonts.contentStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.username,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                  Tooltip(
                    message: user.emailVerified!
                        ? AppLocalizations.of(context)!.verified
                        : AppLocalizations.of(context)!.notVerified,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: user.emailVerified!
                          ? ImageHelper.getSvgIconWithColor(
                              'images/svgs/check-circle.svg',
                              150,
                              150,
                              Colors.green)
                          : ImageHelper.getSvgIconWithColor(
                              'images/svgs/alert.svg', 150, 150, Colors.red),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getLoginStatus(BuildContext context) {
    Map<UserRole, String> userRoleToDisplayNameMap = {
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin
    };
    Map<AccountStatus, String> accountStatusEnumToDisplayValue = {
      AccountStatus.loggedIn: AppLocalizations.of(context)!.accountLoggedIn,
      AccountStatus.loggedOut: AppLocalizations.of(context)!.accountLoggedOut,
      AccountStatus.stopped: AppLocalizations.of(context)!.accountStopped,
      AccountStatus.closed: AppLocalizations.of(context)!.accountClosed,
    };
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Text(
              AppLocalizations.of(context)!.loginInfo,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              AppLocalizations.of(context)!.loginRoleOrLastLoginRole,
              style: OnepieceFonts.contentStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: OnepieceTag.getUserRoleTag(
                user.loginRole!, userRoleToDisplayNameMap[user.loginRole]!),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              AppLocalizations.of(context)!.allUserRoles,
              style: OnepieceFonts.contentStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Row(
              children: user.userRoles
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: OnepieceTag.getUserRoleTag(
                            e, userRoleToDisplayNameMap[e]!),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              AppLocalizations.of(context)!.accountStatus,
              style: OnepieceFonts.contentStyle,
            ),
          ),
          Text(
            accountStatusEnumToDisplayValue[user.accountStatus]!,
            style: OnepieceFonts.fancyBlueHintFont,
          ),
        ],
      ),
    );
  }
}
