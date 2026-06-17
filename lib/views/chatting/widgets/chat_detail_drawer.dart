import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/square_image_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';

class ChatDetailDrawer extends StatefulWidget {
  final Chat chat;
  final String currentUserId;
  final ValueChanged<String>? onRenameChat;
  final VoidCallback? onAddMember;
  final VoidCallback? onLeaveChat;
  final VoidCallback? onClearHistory;

  const ChatDetailDrawer({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onRenameChat,
    this.onAddMember,
    this.onLeaveChat,
    this.onClearHistory,
  });

  @override
  State<ChatDetailDrawer> createState() => _ChatDetailDrawerState();
}

class _ChatDetailDrawerState extends State<ChatDetailDrawer> {
  late final TextEditingController _nameController;

  bool get _isGroup => widget.chat.group == true;
  bool get _isCreator =>
      widget.chat.creationRecord?.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _displayName);
  }

  @override
  void didUpdateWidget(covariant ChatDetailDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id ||
        oldWidget.chat.name != widget.chat.name) {
      _nameController.text = _displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _displayName {
    if (_isGroup) {
      return widget.chat.name ?? '';
    }
    final target = _targetMember;
    return target?.nickname ?? widget.chat.name ?? '';
  }

  User? get _targetMember {
    for (final member in widget.chat.members) {
      if (member.id != widget.currentUserId) return member;
    }
    return widget.chat.members.isEmpty ? null : widget.chat.members.first;
  }

  List<User> get _visibleMembers {
    if (_isGroup) return widget.chat.members;
    return widget.chat.members
        .where((member) => member.id != widget.currentUserId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth =
        screenWidth < 430 ? (screenWidth * 0.86).clamp(280.0, 360.0) : 340.0;

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: OnepieceColors.menuBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildMembersSection(context),
            if (_isGroup && _isCreator) ...[
              const SizedBox(height: 10),
              _buildGroupSettings(context),
            ],
            const SizedBox(height: 10),
            _buildMetadataSection(context),
            const SizedBox(height: 10),
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _DrawerCard(
      child: Column(
        children: [
          _buildAvatarCluster(),
          const SizedBox(height: 10),
          Text(
            _displayName.isEmpty
                ? AppLocalizations.of(context)!.chatting
                : _displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: OnepieceFonts.smallHeaderStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoPill(
                icon: _isGroup ? Icons.groups_outlined : Icons.person_outline,
                label: _isGroup
                    ? AppLocalizations.of(context)!.group
                    : AppLocalizations.of(context)!.chatting,
              ),
              _InfoPill(
                icon: Icons.people_alt_outlined,
                label: '${widget.chat.members.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCluster() {
    if (!_isGroup) {
      final uri = _targetMember?.imageUri ?? '';
      return SquareImageLoader(
        key: ValueKey(uri),
        uriProvider: () => uri,
        width: 64,
        borderWidth: 2,
      );
    }

    final members = widget.chat.members.take(4).toList();
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: members.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final uri = members[index].imageUri ?? '';
          return SquareImageLoader(
            key: ValueKey('${members[index].id}-$uri'),
            uriProvider: () => uri,
            width: 30,
            borderWidth: 1,
          );
        },
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    final members = _visibleMembers;
    return _DrawerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.people_alt_outlined,
            label:
                '${AppLocalizations.of(context)!.member} (${members.length})',
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length + (_isGroup ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              if (_isGroup && index == members.length) {
                return _AddMemberTile(onTap: widget.onAddMember);
              }
              return _MemberTile(member: members[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSettings(BuildContext context) {
    return _DrawerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.edit_note_outlined,
            label: AppLocalizations.of(context)!.name,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _nameController,
                    style: OnepieceFonts.smallContentStyle,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: OnepieceColors.menuHoverColor
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: OnepieceColors.fancyGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty || newName == widget.chat.name) return;
                  widget.onRenameChat?.call(newName);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: OnepieceColors.fancyGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: OnepieceColors.fancyGreen.withValues(alpha: 0.32),
                    ),
                  ),
                  child: const Icon(Icons.check,
                      color: OnepieceColors.fancyGreen, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return _DrawerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.info_outline,
            label: AppLocalizations.of(context)!.chatInformation,
          ),
          const SizedBox(height: 10),
          _MetaRow(
            icon: Icons.lock_outline,
            label: AppLocalizations.of(context)!.chatPrivate,
            value: widget.chat.privateGroup == true
                ? AppLocalizations.of(context)!.yes
                : AppLocalizations.of(context)!.no,
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.mark_chat_unread_outlined,
            label: AppLocalizations.of(context)!.chatUnread,
            value: '${widget.chat.unreadCount ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return _DrawerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.tune_outlined,
            label: AppLocalizations.of(context)!.chatActions,
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.cleaning_services_outlined,
            label: AppLocalizations.of(context)!.clearHistory,
            onTap: widget.onClearHistory,
          ),
          if (_isGroup)
            _ActionTile(
              icon: Icons.logout_outlined,
              label: AppLocalizations.of(context)!.leaveGroup,
              danger: true,
              onTap: widget.onLeaveChat,
            ),
        ],
      ),
    );
  }
}

class _DrawerCard extends StatelessWidget {
  final Widget child;

  const _DrawerCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OnepieceColors.fancyBlue, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnepieceFonts.smallContentFancyBlueStyle,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: OnepieceColors.fancyBlue, size: 15),
          const SizedBox(width: 4),
          Text(label, style: OnepieceFonts.superSmallContentStyle),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final uri = member.imageUri ?? '';
    return Column(
      children: [
        SquareImageLoader(
          key: ValueKey('${member.id}-$uri'),
          uriProvider: () => uri,
          width: 44,
          borderWidth: 1.5,
        ),
        const SizedBox(height: 4),
        Text(
          member.nickname,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: OnepieceFonts.superSmallContentStyle.copyWith(
            color: OnepieceColors.fancyBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AddMemberTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddMemberTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: OnepieceColors.liteFancyBlue,
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.add,
                color: OnepieceColors.fancyBlue, size: 22),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OnepieceColors.menuIconColor, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: OnepieceFonts.superSmallContentStyle,
          ),
        ),
        Text(
          value,
          style: OnepieceFonts.superSmallContentStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: OnepieceColors.fancyBlue,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : OnepieceColors.fancyBlue;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: OnepieceFonts.smallContentStyle.copyWith(
                  color: onTap == null ? OnepieceColors.menuIconColor : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap == null)
              const Icon(Icons.lock_outline,
                  color: OnepieceColors.menuIconColor, size: 15),
          ],
        ),
      ),
    );
  }
}
