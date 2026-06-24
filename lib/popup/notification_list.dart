import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
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
  final double size;
  final double iconSize;

  const NotificationList({
    super.key,
    required BuildContext context,
    this.onRefresh,
    this.size = 38,
    this.iconSize = 22,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  // Initialize as a mutable empty list
  List<Notification> _internalNotifications = [];
  final Set<String> _syncedAcceptedNotificationIds = {};
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
    final chatNotifier = Provider.of<ChatNotifier>(context, listen: false);

    try {
      ListNotificationRequest request =
          ListNotificationRequest(userId: getIt<User>().id, onlyNew: true);
      final response = await getIt<NotificationDao>().list(request);

      if (mounted && response != null) {
        setState(() {
          // FIX 1: Use .toList() to make sure the list is editable (Mutable)
          _internalNotifications = response.notifications.toList();
        });
        _syncAcceptedFriendNotifications(response.notifications, chatNotifier);
      }
    } catch (e) {
      debugPrint("Error polling notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: OnepieceColors.liteFancyBlue.withValues(alpha: 0.35),
        onTap: () => _showNotificationMenu(buttonContext),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ImageHelper.getSvgIcon(
                'images/svgs/notification_false.svg',
                widget.iconSize,
                widget.iconSize,
              ),
              if (_internalNotifications.isNotEmpty)
                Positioned(
                  right: widget.size <= 32 ? 4 : 5,
                  top: widget.size <= 32 ? 4 : 5,
                  child: Container(
                    width: widget.size <= 32 ? 7 : 9,
                    height: widget.size <= 32 ? 7 : 9,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNotificationMenu(BuildContext buttonContext) async {
    _timer?.cancel(); // Pause auto-refresh while popup is open
    await _search();

    if (!mounted || !buttonContext.mounted) return;

    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final buttonTopLeft =
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonRect = buttonTopLeft & buttonBox.size;
    final menuWidth = MediaQuery.sizeOf(context).width < 370
        ? MediaQuery.sizeOf(context).width - 32
        : 320.0;
    final menuLeft = (buttonRect.right - menuWidth)
        .clamp(12.0, overlay.size.width - menuWidth - 12.0)
        .toDouble();
    final menuTop = buttonRect.bottom + 8;
    final menuAnchor = Rect.fromLTWH(
      menuLeft,
      menuTop,
      menuWidth,
      1,
    );

    await showMenu<void>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      position: RelativeRect.fromRect(
        menuAnchor,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: menuWidth,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _internalNotifications.isNotEmpty
                    ? _buildNotificationItems(context)
                    : _buildEmptyState(context),
              ),
            ),
          ),
        ),
      ],
    );

    if (!mounted) return;
    // Resume auto-refresh after popup closes
    _search();
    _startPolling();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.empty,
        textAlign: TextAlign.center,
        style: OnepieceFonts.smallContentStyle.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationItems(BuildContext ctx) {
    return StatefulBuilder(
      builder:
          (BuildContext notificationContext, StateSetter notificationState) {
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _internalNotifications.length,
          itemBuilder: (context, index) {
            final e = _internalNotifications[index];
            return Card(
              elevation: 0,
              margin: EdgeInsets.only(
                bottom: index == _internalNotifications.length - 1 ? 0 : 8,
              ),
              color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              OnepieceColors.fancyBlue.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        _notificationIcon(e),
                        color: OnepieceColors.fancyBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        I18nHelper.getDisplayNameFromI18n(e.content),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: OnepieceFonts.smallContentStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButtons(ctx, e, notificationState),
                  ],
                ),
              ),
            );
          },
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
          _buildActionIconButton(
            icon: Icons.check,
            color: OnepieceColors.fancyGreen,
            onPressed: () =>
                _handleFriendRequest(ctx, e, notificationState, isAccept: true),
          ),
          const SizedBox(width: 4),
          _buildActionIconButton(
            icon: Icons.close,
            color: Colors.red,
            onPressed: () => _handleFriendRequest(ctx, e, notificationState,
                isAccept: false),
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
            final chatNotifier =
                Provider.of<ChatNotifier>(context, listen: false);
            if (e.category == NotificationType.FRIEND_ACCEPTED) {
              await chatNotifier.refreshChats();
              final notificationId = e.id;
              if (notificationId != null) {
                _syncedAcceptedNotificationIds.add(notificationId);
              }
            }

            // 1. Close on Server
            await getIt<NotificationDao>()
                .close(CloseNotificationRequest(notificationId: e.id));

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
            if (ctx.mounted) Navigator.of(ctx).pop();
          } catch (error) {
            debugPrint('Error closing notification: $error');
          }
        },
        icon: const Icon(Icons.check_circle_outline,
            color: OnepieceColors.fancyBlue),
      );
    }
    return const SizedBox.shrink();
  }

  void _syncAcceptedFriendNotifications(
    List<Notification> notifications,
    ChatNotifier chatNotifier,
  ) {
    var needsRefresh = false;
    for (final notification in notifications) {
      if (notification.category != NotificationType.FRIEND_ACCEPTED) {
        continue;
      }
      final notificationId = notification.id;
      if (notificationId == null ||
          _syncedAcceptedNotificationIds.contains(notificationId)) {
        continue;
      }
      _syncedAcceptedNotificationIds.add(notificationId);
      needsRefresh = true;
    }
    if (needsRefresh) {
      chatNotifier.refreshChats();
    }
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  IconData _notificationIcon(Notification notification) {
    if (notification.category == NotificationType.FRIEND_REQUEST) {
      return Icons.person_add_alt_1_outlined;
    }
    if (notification.category == NotificationType.FRIEND_ACCEPTED) {
      return Icons.verified_user_outlined;
    }
    if (notification.category == NotificationType.FRIEND_REJECT) {
      return Icons.person_off_outlined;
    }
    return Icons.notifications_none_outlined;
  }

  Future<void> _handleFriendRequest(
      BuildContext ctx, Notification e, StateSetter notificationState,
      {required bool isAccept}) async {
    // For friend requests, we usually want to close the popup
    // immediately to avoid double-clicking or waiting.
    Navigator.of(ctx).pop();

    try {
      if (isAccept) {
        final chatNotifier = Provider.of<ChatNotifier>(context, listen: false);

        await getIt<UserDao>().acceptFriend(
            AcceptFriendRequest(friendId: e.notificationSourceId));

        final CreateChatRequest request = CreateChatRequest(
            type: MessageType.CREATE_CHAT,
            ids: [e.notificationSourceId!, e.notificationTargetId!]);
        final chat = await getIt<ChattingDao>().createChat(request);

        if (chat != null) {
          chatNotifier.upsertChat(chat);
        } else {
          chatNotifier.sendChatMessage(jsonEncode(request.toJson()));
        }
      } else {
        await getIt<UserDao>().rejectFriend(
            RejectFriendRequest(friendId: e.notificationSourceId));
      }

      await getIt<NotificationDao>()
          .close(CloseNotificationRequest(notificationId: e.id));

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
