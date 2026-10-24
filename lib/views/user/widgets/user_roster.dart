import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/date_helper.dart';

/// The user list body: a card list on mobile, a spotlight grid on desktop.
/// Each card shows the avatar, nickname/username, login role, email-verified
/// state, account status and the user's role tags.
class UserRoster extends StatelessWidget {
  final List<User> users;
  final ScrollController controller;
  final bool isNarrow;

  const UserRoster({
    super.key,
    required this.users,
    required this.controller,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  Map<UserRole, String> _roleMap(BuildContext context) => {
        UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
        UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
        UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
        UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin,
      };

  Map<AccountStatus, String> _accountMap(BuildContext context) => {
        AccountStatus.loggedIn: AppLocalizations.of(context)!.accountLoggedIn,
        AccountStatus.loggedOut: AppLocalizations.of(context)!.accountLoggedOut,
        AccountStatus.stopped: AppLocalizations.of(context)!.accountStopped,
        AccountStatus.closed: AppLocalizations.of(context)!.accountClosed,
      };

  // ── Mobile: card-based user list ─────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final roleMap = _roleMap(context);
    final accountMap = _accountMap(context);

    if (users.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }

    return ListView.builder(
      controller: controller,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('userDetails',
                extra: user.id, pathParameters: {'name': user.nickname}),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      ImageLazyLoader(
                          uriProvider: () => user.imageUri ?? '',
                          width: 44,
                          borderWidth: 1.5,
                          borderRadios: 44),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(user.nickname,
                                style: OnepieceFonts.headerStyle
                                    .copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(user.username,
                                style: OnepieceFonts.smallContentStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ])),
                      if (user.loginRole != null)
                        OnepieceTag.getUserRoleTag(
                            user.loginRole!, roleMap[user.loginRole]!),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                                user.emailVerified == true
                                    ? Icons.check
                                    : Icons.cancel,
                                size: 16,
                                color: user.emailVerified == true
                                    ? Colors.greenAccent
                                    : Colors.redAccent),
                            const SizedBox(width: 4),
                            Text(
                                user.emailVerified == true
                                    ? AppLocalizations.of(context)!.verified
                                    : AppLocalizations.of(context)!.notVerified,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: user.emailVerified == true
                                        ? Colors.greenAccent
                                        : Colors.redAccent)),
                          ]),
                          Text(accountMap[user.accountStatus] ?? '',
                              style: OnepieceFonts.smallContentStyle),
                        ]),
                    if (user.userRoles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: user.userRoles
                              .map((e) =>
                                  OnepieceTag.getUserRoleTag(e, roleMap[e]!))
                              .toList()),
                    ],
                    const SizedBox(height: 4),
                    Text(
                        user.creationRecord?.actionTimestamp != null
                            ? DateHelper.getFormattedDatetimeFromTimestamp(
                                user.creationRecord!.actionTimestamp!, context)
                            : '',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
            ),
          ),
        );
      },
    );
  }

  // ── Desktop: spotlight grid ───────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }
    final roleMap = _roleMap(context);
    final accountMap = _accountMap(context);

    return DesktopSpotlightGrid<User>(
      items: users,
      idOf: (user) => user.id,
      controller: controller,
      cardBuilder: (context, user) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.goNamed('userDetails',
              extra: user.id, pathParameters: {'name': user.nickname}),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ImageLazyLoader(
                    key: ValueKey(user.imageUri),
                    uriProvider: () => user.imageUri ?? '',
                    width: 54,
                    borderWidth: 1.5,
                    borderRadios: 54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nickname,
                            style: OnepieceFonts.contentStyleBold.copyWith(
                                color: OnepieceColors.deepFancyBlue,
                                fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(user.username,
                            style: OnepieceFonts.smallContentStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (user.loginRole != null)
                    OnepieceTag.getUserRoleTag(
                        user.loginRole!, roleMap[user.loginRole]!),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(
                      user.emailVerified == true
                          ? Icons.verified
                          : Icons.cancel,
                      size: 17,
                      color: user.emailVerified == true
                          ? Colors.green
                          : Colors.red),
                  const SizedBox(width: 5),
                  Text(
                    user.emailVerified == true
                        ? AppLocalizations.of(context)!.verified
                        : AppLocalizations.of(context)!.notVerified,
                    style: OnepieceFonts.smallContentStyle,
                  ),
                  const Spacer(),
                  Text(accountMap[user.accountStatus] ?? '',
                      style: OnepieceFonts.boldFancySmallFont),
                ]),
                if (user.userRoles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: user.userRoles
                        .map((role) =>
                            OnepieceTag.getUserRoleTag(role, roleMap[role]!))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
