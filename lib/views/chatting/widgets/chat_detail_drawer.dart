import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Compact conversation details. The drawer is intentionally split into
/// clearly bounded identity and action/member surfaces.
class ChatDetailDrawer extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback? onAddMember;
  final ValueChanged<User>? onOpenProfile;

  // Kept for source compatibility; these actions have no server endpoint.
  final ValueChanged<String>? onRenameChat;
  final VoidCallback? onLeaveChat;
  final VoidCallback? onClearHistory;

  const ChatDetailDrawer({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onAddMember,
    this.onOpenProfile,
    this.onRenameChat,
    this.onLeaveChat,
    this.onClearHistory,
  });

  bool get _isGroup => chat.group == true;

  User? get _otherUser {
    for (final user in chat.members) {
      if (user.id != currentUserId) return user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 430 ? width * .9 : 352,
      elevation: 0,
      backgroundColor: OnepieceColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(children: [
          Container(
            height: 56,
            padding: const EdgeInsets.fromLTRB(18, 0, 10, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(bottom: BorderSide(color: OnepieceColors.separator)),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _isGroup ? loc.chatGroupDetails : loc.chatContactDetails,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                color: OnepieceColors.secondaryLabel,
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _identityCard(loc),
                if (_isGroup) ...[
                  const SizedBox(height: 12),
                  _membersCard(loc),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _identityCard(AppLocalizations loc) {
    final other = _otherUser;
    final name = _isGroup
        ? (chat.name?.trim().isNotEmpty == true
            ? chat.name!.trim()
            : loc.chatGroupDetails)
        : (other?.nickname ?? loc.chatContactDetails);
    return _SurfaceCard(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _isGroup
                ? _GroupAvatar(members: chat.members)
                : _UserAvatar(user: other, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: OnepieceColors.primaryLabel)),
                  const SizedBox(height: 4),
                  Text(
                    _isGroup
                        ? loc.userCount(chat.members.length)
                        : (other?.username ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: OnepieceColors.secondaryLabel),
                  ),
                ],
              ),
            ),
          ]),
        ),
        if (!_isGroup && other != null && onOpenProfile != null) ...[
          const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: OnepieceColors.separator),
          InkWell(
            onTap: () => onOpenProfile!(other),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
              child: Row(children: [
                const Icon(Icons.person_outline,
                    size: 19, color: OnepieceColors.fancyBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(loc.chatViewProfile,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: OnepieceColors.primaryLabel)),
                ),
                const Icon(Icons.chevron_right,
                    size: 19, color: OnepieceColors.secondaryLabel),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _membersCard(AppLocalizations loc) => _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(children: [
                Expanded(
                  child: Text(loc.chatMembers,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.primaryLabel)),
                ),
                if (onAddMember != null)
                  TextButton.icon(
                    onPressed: onAddMember,
                    icon: const Icon(Icons.add, size: 17),
                    label: Text(loc.chatAddMembers),
                    style: TextButton.styleFrom(
                      foregroundColor: OnepieceColors.fancyBlue,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ]),
            ),
            const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: OnepieceColors.separator),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 13,
                children: [
                  for (final user in chat.members)
                    SizedBox(
                      width: 55,
                      child: InkWell(
                        onTap: onOpenProfile == null
                            ? null
                            : () => onOpenProfile!(user),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(children: [
                          _UserAvatar(user: user, size: 43),
                          const SizedBox(height: 5),
                          Text(user.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: OnepieceColors.primaryLabel)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnepieceColors.separator, width: .7),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  const _UserAvatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final uri = user?.imageUri ?? '';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: OnepieceColors.surface,
        shape: BoxShape.circle,
      ),
      child: uri.isEmpty
          ? Icon(Icons.person_outline,
              size: size * .48, color: OnepieceColors.secondaryLabel)
          : ClipOval(
              child: ImageLazyLoader(
                key: ValueKey('${user?.id}-$uri'),
                uriProvider: () => uri,
                width: size,
                borderWidth: 0,
                borderRadios: size,
              ),
            ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final List<User> members;
  const _GroupAvatar({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(4).toList();
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: visible.isEmpty
          ? const Icon(Icons.group_outlined,
              size: 28, color: OnepieceColors.secondaryLabel)
          : GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [
                for (final user in visible) _UserAvatar(user: user, size: 22),
              ],
            ),
    );
  }
}
