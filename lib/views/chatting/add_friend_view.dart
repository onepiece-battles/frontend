import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'add_friend_controller.dart';
import 'widgets/chat_user_search_widgets.dart';

Timer? _timer;

class AddFriendView extends StatefulWidget {
  const AddFriendView({super.key});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final TextEditingController searchUserController = TextEditingController();
  final ScrollController userListController = ScrollController();
  final AddFriendController _controller = AddFriendController();
  List<User> users = [];
  String selectedUserId = "";
  UserFilter userFilter = UserFilter();

  @override
  void dispose() {
    _timer?.cancel();
    searchUserController.dispose();
    userListController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, localSetState) {
      final screenSize = MediaQuery.of(context).size;
      final dialogWidth =
          screenSize.width < 430 ? screenSize.width - 32 : 410.0;
      final dialogHeight = (screenSize.height * 0.68).clamp(380.0, 580.0);

      return SizedBox(
        width: dialogWidth,
        height: dialogHeight.toDouble(),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: OnepieceColors.separator),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: searchUserController,
                    decoration: chatUserSearchDecoration(
                        AppLocalizations.of(context)!.userNameLabel),
                    onChanged: (value) {
                      if (_timer?.isActive ?? false) _timer?.cancel();
                      _timer = Timer(const Duration(milliseconds: 500), () {
                        userFilter.nickname = value;
                        final listUserRequest = ListUsersRequest(
                          pageSize: 5,
                          pageIndex: 1,
                          sortKeys: [],
                          userFilter: userFilter,
                        );
                        _controller
                            .listUser(listUserRequest)
                            .then((value) {
                          if (!mounted) return;
                          localSetState(() {
                            users = value?.users ?? [];
                          });
                        });
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  controller: userListController,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isMe = user.id == getIt<User>().id;
                    final isSelected = selectedUserId == user.id;
                    return ChatUserSearchCard(
                      user: user,
                      selected: isSelected,
                      disabled: isMe,
                      circularAvatar: true,
                      onTap: isMe
                          ? null
                          : () {
                              localSetState(() {
                                selectedUserId = isSelected ? "" : user.id;
                              });
                            },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: selectedUserId == ""
                            ? null
                            : () {
                                localSetState(() {
                                  selectedUserId = "";
                                });
                              },
                        child: Text(AppLocalizations.of(context)!.cancelPopUp),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedUserId == ""
                            ? null
                            : () {
                                final navigator = Navigator.of(context);
                                _controller
                                    .addFriend(AddFriendRequest(
                                        friendId: selectedUserId))
                                    .then((value) {
                                  if (!mounted) return;
                                  if (value?.result == true) {
                                    selectedUserId = "";
                                  }
                                  navigator.pop();
                                });
                              },
                        child: Text(AppLocalizations.of(context)!.submitForm),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: OnepieceColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.group_add_outlined,
                color: OnepieceColors.fancyBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.addFriend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnepieceFonts.smallHeaderStyle.copyWith(fontSize: 18, color: OnepieceColors.primaryLabel),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: OnepieceColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}
