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
import '../../utils/responsive_breakpoints.dart';

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
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = ResponsiveBreakpoints.isMobileFromConstraints(constraints);
              return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: isNarrow ? const EdgeInsets.fromLTRB(12, 12, 12, 20) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getBasicInfo(context),
                const SizedBox(height: 12),
                _getLoginStatus(context),
                const SizedBox(height: 12),
              ],
            ),
          );
            },
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
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.basicInfo, style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        Center(child: ImageHelper.getRoundImageFrame(120, 120, 3, OnepieceColors.liteFancyBlue, 120, Base64Helper.decode(user.profileImage ?? ''))),
        const SizedBox(height: 8),
        _readOnlyRow(context, AppLocalizations.of(context)!.nickname, user.nickname),
        const SizedBox(height: 6),
        _readOnlyRow(context, AppLocalizations.of(context)!.email, user.username, trailing: Tooltip(
          message: user.emailVerified! ? AppLocalizations.of(context)!.verified : AppLocalizations.of(context)!.notVerified,
          child: SizedBox(width: 24, height: 24,
            child: user.emailVerified! ? ImageHelper.getSvgIconWithColor('images/svgs/check-circle.svg', 150, 150, Colors.green) : ImageHelper.getSvgIconWithColor('images/svgs/alert.svg', 150, 150, Colors.red)),
        )),
      ])),
    );
  }

  Widget _readOnlyRow(BuildContext context, String label, String value, {Widget? trailing}) {
    return Row(children: [
      Text(label, style: OnepieceFonts.deepBlackHintFont),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: OnepieceFonts.contentStyle.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      if (trailing != null) trailing,
    ]);
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
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.loginInfo, style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context)!.loginRoleOrLastLoginRole, style: OnepieceFonts.contentStyle),
        const SizedBox(height: 6),
        OnepieceTag.getUserRoleTag(user.loginRole!, userRoleToDisplayNameMap[user.loginRole]!),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.allUserRoles, style: OnepieceFonts.contentStyle),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: user.userRoles.map((e) => OnepieceTag.getUserRoleTag(e, userRoleToDisplayNameMap[e]!)).toList()),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.accountStatus, style: OnepieceFonts.contentStyle),
        const SizedBox(height: 6),
        Text(accountStatusEnumToDisplayValue[user.accountStatus]!, style: OnepieceFonts.fancyBlueHintFont),
      ])),
    );
  }
}
