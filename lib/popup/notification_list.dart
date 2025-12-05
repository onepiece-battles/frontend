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
  final VoidCallback? onRefresh; // Added onRefresh callback

  const NotificationList({
    super.key,
    required this.notifications,
    required BuildContext
        context, // Keep this if it's used elsewhere for context
    this.onRefresh, // Make it optional
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  // It's good practice to make a mutable copy of the list if you're
  // modifying it within the StatefulWidget, rather than modifying the
  // final list passed via widget.notifications directly.
  // This helps avoid unexpected side effects if the parent widget assumes
  // its list won't change directly.
  List<Notification> _internalNotifications = [];

  @override
  void initState() {
    super.initState();
    _internalNotifications = List.from(widget.notifications);
  }

  @override
  void didUpdateWidget(covariant NotificationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal list if the parent provides a new list instance
    if (oldWidget.notifications != widget.notifications) {
      _internalNotifications = List.from(widget.notifications);
    }
  }

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
        barrierColor: Colors.transparent,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (ctx) => // Use ctx for inner context
            _internalNotifications.isNotEmpty
                ? StatefulBuilder(
                    builder: (BuildContext notificationContext,
                        StateSetter notificationState) {
                      return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _internalNotifications
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        // Use Expanded to prevent overflow for long text
                                        child: Text(
                                          I18nHelper.getDisplayNameFromI18n(
                                              e.content),
                                          style: OnepieceFonts.tagStyle,
                                        ),
                                      ),
                                      if (e.category ==
                                          NotificationType.FRIEND_REQUEST)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                                onPressed: () async {
                                                  // Use async for await
                                                  try {
                                                    await getIt<UserDao>()
                                                        .acceptFriend(
                                                            AcceptFriendRequest(
                                                                friendId: e
                                                                    .notificationSourceId));
                                                    await getIt<
                                                            NotificationDao>()
                                                        .close(
                                                            CloseNotificationRequest(
                                                                notificationId:
                                                                    e.id));
                                                    await getIt<ChattingDao>()
                                                        .createChat(
                                                            CreateChatRequest(
                                                                type: MessageType
                                                                    .CREATE_CHAT,
                                                                ids: [
                                                          e.notificationSourceId!,
                                                          e.notificationTargetId!
                                                        ]));
                                                    notificationState(() {
                                                      _internalNotifications
                                                          .removeWhere((el) =>
                                                              el.id == e.id);
                                                    });
                                                    widget.onRefresh
                                                        ?.call(); // Notify parent
                                                  } catch (error) {
                                                    debugPrint(
                                                        'Error accepting friend: $error');
                                                    // Handle error (e.g., show a SnackBar)
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                )),
                                            IconButton(
                                                onPressed: () async {
                                                  // Use async for await
                                                  try {
                                                    await getIt<UserDao>()
                                                        .rejectFriend(
                                                            RejectFriendRequest(
                                                                friendId: e
                                                                    .notificationSourceId));
                                                    await getIt<
                                                            NotificationDao>()
                                                        .close(
                                                            CloseNotificationRequest(
                                                                notificationId:
                                                                    e.id));
                                                    notificationState(() {
                                                      _internalNotifications
                                                          .removeWhere((el) =>
                                                              el.id == e.id);
                                                    });
                                                    widget.onRefresh
                                                        ?.call(); // Notify parent
                                                  } catch (error) {
                                                    debugPrint(
                                                        'Error rejecting friend: $error');
                                                    // Handle error
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  color: Colors.white,
                                                ))
                                          ],
                                        )
                                      else if (e.category ==
                                              NotificationType
                                                  .FRIEND_ACCEPTED ||
                                          e.category ==
                                              NotificationType.FRIEND_REJECT)
                                        IconButton(
                                            onPressed: () async {
                                              // Use async for await
                                              try {
                                                await getIt<NotificationDao>()
                                                    .close(
                                                        CloseNotificationRequest(
                                                            notificationId:
                                                                e.id));
                                                notificationState(() {
                                                  _internalNotifications
                                                      .removeWhere((el) =>
                                                          el.id == e.id);
                                                });
                                                widget.onRefresh
                                                    ?.call(); // Notify parent
                                              } catch (error) {
                                                debugPrint(
                                                    'Error closing notification: $error');
                                                // Handle error
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            )),
                                    ],
                                  ),
                                ),
                              )
                              .toList());
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppLocalizations.of(context)!.empty,
                          style: OnepieceFonts.tagStyle,
                        ),
                      )
                    ],
                  ),
      ),
      child: ImageHelper.getSvgIcon(
        _internalNotifications.isEmpty // Check the internal list
            ? 'images/svgs/notification_false.svg'
            : 'images/svgs/notification_true.svg',
        25,
        25,
      ),
    );
  }
}
