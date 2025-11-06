import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../l10n/app_localizations.dart';
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
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: () => showPopover(
        width: 300,
        direction: PopoverDirection.bottom,
        context: context,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (context) =>
            widget.notifications.isNotEmpty?
            StatefulBuilder(
                builder: (BuildContext context, StateSetter notificationState) {
                  return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.notifications
                          .map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(I18nHelper.getDisplayNameFromI18n(e.content), style: OnepieceFonts.tagStyle,),
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
                                            notificationState(() {
                                              widget.notifications.removeWhere((el)=>el.id ==e.id);
                                            });
                                          });
                                        },
                                        icon: const Icon(Icons.check, color: Colors.white,)),
                                    IconButton(
                                        onPressed: () {
                                          getIt<UserDao>()
                                              .rejectFriend(RejectFriendRequest(
                                              friendId: e.notificationSourceId))
                                              .then((value) {
                                            getIt<NotificationDao>().close(
                                                CloseNotificationRequest(
                                                    notificationId: e.id));
                                            notificationState(() {
                                              widget.notifications.removeWhere((el)=>el.id ==e.id);
                                            });
                                          });
                                        },
                                        icon: const Icon(Icons.cancel_outlined, color: Colors.white,))
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
                                    icon: const Icon(Icons.check, color: Colors.white,)),
                            ],
                          ),
                        ),
                      )
                          .toList());
                }
            )
            :
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Text(AppLocalizations.of(context)!.empty, style: OnepieceFonts.tagStyle,),
           )
          ],
        )
        ,
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
