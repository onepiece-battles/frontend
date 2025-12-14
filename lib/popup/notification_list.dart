import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import '../components/chat_notifier.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../l10n/app_localizations.dart';
import '../repository/user_dao.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class NotificationList extends StatefulWidget {
  final VoidCallback? onRefresh;

  const NotificationList({
    super.key,
    required BuildContext context,
    this.onRefresh,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  // Initialize as a mutable empty list
  List<Notification> _internalNotifications = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _search();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _search();
    });
  }

  Future<void> _search() async {
    if (!mounted) return;

    try {
      ListNotificationRequest request = ListNotificationRequest(
          userId: getIt<User>().id,
          onlyNew: true
      );
      final response = await getIt<NotificationDao>().list(request);

      if (mounted && response != null) {
        setState(() {
          // FIX 1: Use .toList() to make sure the list is editable (Mutable)
          _internalNotifications = response.notifications.toList();
        });
      }
    } catch (e) {
      debugPrint("Error polling notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: () async {
        _timer?.cancel(); // Pause auto-refresh while popup is open
        await _search();

        if (!context.mounted) return;

        await showPopover(
          width: 300,
          direction: PopoverDirection.bottom,
          context: context,
          barrierColor: Colors.transparent,
          backgroundColor: OnepieceColors.fancyBlue,
          bodyBuilder: (ctx) => _internalNotifications.isNotEmpty
              ? _buildNotificationItems(ctx)
              : _buildEmptyState(context),
        );

        // Resume auto-refresh after popup closes
        _search();
        _startPolling();
      },
      child: ImageHelper.getSvgIcon(
        _internalNotifications.isEmpty
            ? 'images/svgs/notification_false.svg'
            : 'images/svgs/notification_true.svg',
        25,
        25,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildNotificationItems(BuildContext ctx) {
    return StatefulBuilder(
      builder: (BuildContext notificationContext, StateSetter notificationState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: _internalNotifications.map((e) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      I18nHelper.getDisplayNameFromI18n(e.content),
                      style: OnepieceFonts.tagStyle,
                    ),
                  ),
                  _buildActionButtons(ctx, e, notificationState),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext ctx, Notification e, StateSetter notificationState) {

    // CASE 1: Friend Request (Accept/Reject)
    if (e.category == NotificationType.FRIEND_REQUEST) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _handleFriendRequest(
                ctx, e, notificationState, isAccept: true),
            icon: const Icon(Icons.check, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _handleFriendRequest(
                ctx, e, notificationState, isAccept: false),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
          )
        ],
      );
    }
    // CASE 2: Info Notifications (Accepted/Rejected Info)
    else if (e.category == NotificationType.FRIEND_ACCEPTED ||
        e.category == NotificationType.FRIEND_REJECT) {
      return IconButton(
        onPressed: () async {
          try {
            // 1. Close on Server
            await getIt<NotificationDao>().close(
                CloseNotificationRequest(notificationId: e.id)
            );

            // 2. Update UI inside Popup (using StateSetter)
            notificationState(() {
              _internalNotifications.removeWhere((el) => el.id == e.id);
            });

            // 3. Update UI on Parent Icon (using setState)
            // This is safe now because _internalNotifications is a mutable .toList()
            if (mounted) {
              setState(() {
                // The list is reference-shared, but we trigger rebuild to check .isEmpty
                // Logic: removeWhere already modified the list object in step 2.
                // We just need to tell flutter to redraw the bell icon.
              });
            }

            // 4. Close the Popup
            if(ctx.mounted) Navigator.of(ctx).pop();

          } catch (error) {
            debugPrint('Error closing notification: $error');
          }
        },
        icon: const Icon(Icons.check, color: Colors.white),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleFriendRequest(BuildContext ctx, Notification e,
      StateSetter notificationState, {required bool isAccept}) async {

    // For friend requests, we usually want to close the popup
    // immediately to avoid double-clicking or waiting.
    Navigator.of(ctx).pop();

    try {
      if (isAccept) {
        final CreateChatRequest request = CreateChatRequest(
            type: MessageType.CREATE_CHAT,
            ids: [e.notificationSourceId!, e.notificationTargetId!]);

        if (context.mounted) {
          Provider.of<ChatNotifier>(context, listen: false)
              .sendChatMessage(jsonEncode(request.toJson()));
        }

        await getIt<UserDao>().acceptFriend(
            AcceptFriendRequest(friendId: e.notificationSourceId)
        );
      } else {
        await getIt<UserDao>().rejectFriend(
            RejectFriendRequest(friendId: e.notificationSourceId)
        );
      }

      await getIt<NotificationDao>().close(
          CloseNotificationRequest(notificationId: e.id)
      );

      // Update local state immediately
      if (mounted) {
        setState(() {
          _internalNotifications.removeWhere((el) => el.id == e.id);
        });
      }

      widget.onRefresh?.call();

    } catch (error) {
      debugPrint('Error handling friend request: $error');
    }
  }
}
