import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/user_dao.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class NotificationList extends StatefulWidget {
  final List<Notification> notifications;
  const NotificationList(
      {super.key, required this.notifications, required BuildContext context});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showPopover(
        width: 300,
        height: 70,
        direction: PopoverDirection.bottom,
        context: context,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (context) => Column(
            children: widget.notifications
                .map(
                  (e) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18nHelper.getDisplayNameFromI18n(e.content)),
                      if (e.category == NotificationType.FRIEND_REQUEST)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                                onPressed: () {
                                  getIt<UserDao>()
                                      .acceptFriend(AcceptFriendRequest(
                                          friendId: e.notificationSourceId))
                                      .then((value) {
                                    getIt<NotificationDao>().close(
                                        CloseNotificationRequest(
                                            notificationId: e.id));
                                    getIt<ChattingDao>().createChat(
                                        CreateChatRequest(ids: [
                                      e.notificationSourceId!,
                                      e.notificationTargetId!
                                    ]));
                                  });
                                },
                                icon: const Icon(Icons.check)),
                            IconButton(
                                onPressed: () {
                                  getIt<UserDao>()
                                      .rejectFriend(RejectFriendRequest(
                                          friendId: e.notificationSourceId))
                                      .then((value) {
                                    getIt<NotificationDao>().close(
                                        CloseNotificationRequest(
                                            notificationId: e.id));
                                  });
                                },
                                icon: const Icon(Icons.cancel_outlined))
                          ],
                        )
                      else if (e.category == NotificationType.FRIEND_ACCEPTED ||
                          e.category == NotificationType.FRIEND_REJECT)
                        IconButton(
                            onPressed: () {
                              getIt<NotificationDao>().close(
                                  CloseNotificationRequest(
                                      notificationId: e.id));
                            },
                            icon: const Icon(Icons.check)),
                    ],
                  ),
                )
                .toList()),
      ),
      child: ImageHelper.getSvgIcon(
        widget.notifications.isEmpty
            ? 'images/svgs/notification_false.svg'
            : 'images/svgs/notification_true.svg',
        25,
        25,
      ),
    );
  }
}
