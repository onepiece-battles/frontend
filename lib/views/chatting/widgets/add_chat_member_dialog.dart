import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../repository/chatting_dao.dart';
import '../../../repository/user_dao.dart';

/// Adds friends to an existing group conversation using the join-chat API.
class AddChatMemberDialog extends StatefulWidget {
  final Chat chat;
  final String currentUserId;
  final ValueChanged<Chat> onMembersAdded;
  final UserDao? userDao;
  final ChattingDao? chattingDao;

  const AddChatMemberDialog({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onMembersAdded,
    this.userDao,
    this.chattingDao,
  });

  @override
  State<AddChatMemberDialog> createState() => _AddChatMemberDialogState();
}

class _AddChatMemberDialogState extends State<AddChatMemberDialog> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};
  List<User> _candidates = [];
  bool _loading = true;
  bool _submitting = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final dao = widget.userDao ?? GetIt.I<UserDao>();
      final response =
          await dao.listFriend(ListFriendRequest(userId: widget.currentUserId));
      if (!mounted) return;
      final existing = widget.chat.members.map((user) => user.id).toSet();
      setState(() {
        _candidates = (response?.users ?? [])
            .where((user) =>
                user.id != widget.currentUserId && !existing.contains(user.id))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty || _submitting || widget.chat.id == null) return;
    setState(() => _submitting = true);
    try {
      final dao = widget.chattingDao ?? GetIt.I<ChattingDao>();
      final updated = await dao.joinChat(JoinChatRequest(
        conversationId: widget.chat.id,
        ids: [widget.currentUserId, ..._selectedIds],
      ));
      if (updated == null) throw StateError('No updated conversation');
      if (!mounted) return;
      widget.onMembersAdded(updated);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.chatAddMembersFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _candidates
        .where((user) =>
            user.nickname.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query))
        .toList();
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: size.width < 430 ? size.width - 32 : 390,
        height: (size.height * .72).clamp(350.0, 600.0),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
            child: Row(children: [
              Expanded(
                child: Text(loc.chatAddMembers,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: OnepieceColors.primaryLabel)),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ]),
          ),
          const Divider(height: 1, color: OnepieceColors.separator),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: loc.chatSearchFriends,
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: OnepieceColors.secondaryLabel),
                filled: true,
                fillColor: OnepieceColors.surface,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _loadFailed
                    ? Center(
                        child: TextButton(
                            onPressed: _loadFriends,
                            child: Text(loc.retryLoading)))
                    : filtered.isEmpty
                        ? Center(
                            child: Text(loc.chatNoFriendsToAdd,
                                style: const TextStyle(
                                    color: OnepieceColors.secondaryLabel)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final user = filtered[index];
                              final selected = _selectedIds.contains(user.id);
                              return _FriendChoiceRow(
                                user: user,
                                selected: selected,
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(user.id);
                                  } else {
                                    _selectedIds.add(user.id);
                                  }
                                }),
                              );
                            },
                          ),
          ),
          const Divider(height: 1, color: OnepieceColors.separator),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedIds.isEmpty || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: OnepieceColors.fancyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(loc.confirm),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FriendChoiceRow extends StatelessWidget {
  final User user;
  final bool selected;
  final VoidCallback onTap;

  const _FriendChoiceRow(
      {required this.user, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uri = user.imageUri ?? '';
    return Column(children: [
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: OnepieceColors.surface,
              child: uri.isEmpty
                  ? const Icon(Icons.person_outline,
                      color: OnepieceColors.secondaryLabel)
                  : ClipOval(
                      child: ImageLazyLoader(
                        key: ValueKey('${user.id}-$uri'),
                        uriProvider: () => uri,
                        width: 44,
                        borderWidth: 0,
                        borderRadios: 44,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, color: OnepieceColors.primaryLabel)),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 21,
              color: selected
                  ? OnepieceColors.fancyBlue
                  : OnepieceColors.secondaryLabel,
            ),
          ]),
        ),
      ),
      const Divider(height: 1, color: OnepieceColors.separator),
    ]);
  }
}
