import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Group conversations show their members; direct conversations show the
/// other person's details. Only working actions are presented.
class ChatDetailDrawer extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback? onAddMember;
  final ValueChanged<User>? onOpenProfile;

  // Retained for source compatibility. These actions have no server endpoint.
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
    final title = _isGroup
        ? (chat.name?.trim().isNotEmpty == true
            ? chat.name!.trim()
            : loc.chatGroupDetails)
        : (_otherUser?.nickname ?? loc.chatContactDetails);
    return Drawer(
      width: width < 430 ? width * .9 : 360,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 14, 14),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _isGroup ? loc.chatGroupDetails : loc.chatContactDetails,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: OnepieceColors.primaryLabel),
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
            const Divider(height: 1, color: OnepieceColors.separator),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  Center(
                    child: _isGroup
                        ? _GroupAvatar(members: chat.members)
                        : _UserAvatar(user: _otherUser, size: 76),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: OnepieceColors.primaryLabel),
                  ),
                  if (_isGroup) ...[
                    const SizedBox(height: 7),
                    Text(
                      loc.userCount(chat.members.length),
                      style: const TextStyle(
                          fontSize: 13, color: OnepieceColors.secondaryLabel),
                    ),
                  ],
                  const SizedBox(height: 34),
                  if (_isGroup) _groupMembers(loc) else _contactDetails(loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupMembers(AppLocalizations loc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(loc.chatMembers),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 20,
            children: [
              for (final member in chat.members)
                _MemberItem(
                  user: member,
                  onTap: onOpenProfile == null
                      ? null
                      : () => onOpenProfile!(member),
                ),
              if (onAddMember != null)
                _AddMemberItem(label: loc.chatAddMembers, onTap: onAddMember!),
            ],
          ),
        ],
      );

  Widget _contactDetails(AppLocalizations loc) {
    final user = _otherUser;
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(loc.basicInfo),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: OnepieceColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _DetailRow(label: loc.nickname, value: user.nickname),
            const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: OnepieceColors.separator),
            _DetailRow(label: loc.userNameLabel, value: user.username),
          ]),
        ),
        if (onOpenProfile != null) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onOpenProfile!(user),
              icon: const Icon(Icons.person_outline, size: 19),
              label: Text(loc.chatViewProfile),
              style: FilledButton.styleFrom(
                backgroundColor: OnepieceColors.fancyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: OnepieceColors.primaryLabel),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: OnepieceColors.secondaryLabel)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13, color: OnepieceColors.primaryLabel)),
          ),
        ]),
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
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: OnepieceColors.separator),
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
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(18)),
      child: visible.isEmpty
          ? const Icon(Icons.group_outlined,
              size: 34, color: OnepieceColors.secondaryLabel)
          : GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: [
                for (final user in visible) _UserAvatar(user: user, size: 30),
              ],
            ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  const _MemberItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 68,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(children: [
            _UserAvatar(user: user, size: 52),
            const SizedBox(height: 6),
            Text(user.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: OnepieceColors.primaryLabel)),
          ]),
        ),
      );
}

class _AddMemberItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddMemberItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 68,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: OnepieceColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: OnepieceColors.separator),
              ),
              child: const Icon(Icons.add,
                  color: OnepieceColors.fancyBlue, size: 25),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: OnepieceColors.fancyBlue)),
          ]),
        ),
      );
}
