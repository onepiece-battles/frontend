import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/chat_user_search_widgets.dart';

class CreateChattingView extends StatefulWidget {
  const CreateChattingView({super.key});

  @override
  State<CreateChattingView> createState() => _CreateChattingViewState();
}

class _CreateChattingViewState extends State<CreateChattingView> {
  final TextEditingController searchFriendController = TextEditingController();
  final ScrollController userListController = ScrollController();
  Set<String> selectedUserIds = {};
  List<User> allUsers = [];
  List<User> users = [];

  void _listUser() {
    getIt<UserDao>()
        .listFriend(ListFriendRequest(userId: getIt<User>().id))
        .then((value) {
      if (!mounted) return;
      setState(() {
        allUsers = value?.users ?? [];
        users = allUsers;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _listUser();
  }

  @override
  void dispose() {
    searchFriendController.dispose();
    userListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, localSetState) {
      final screenSize = MediaQuery.of(context).size;
      final dialogWidth =
          screenSize.width < 430 ? screenSize.width - 32 : 380.0;
      final dialogHeight = (screenSize.height * 0.72).clamp(420.0, 620.0);

      return SizedBox(
        width: dialogWidth,
        height: dialogHeight.toDouble(),
        child: Card(
          elevation: 4,
          color: Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: searchFriendController,
                    decoration: chatUserSearchDecoration(
                        AppLocalizations.of(context)!.userNameLabel),
                    onChanged: (value) {
                      localSetState(() {
                        final filter = value.trim().toLowerCase();
                        users = filter.isEmpty
                            ? allUsers
                            : allUsers
                                .where((user) => user.nickname
                                    .toLowerCase()
                                    .contains(filter))
                                .toList();
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
                    final selected = selectedUserIds.contains(user.id);
                    return ChatUserSearchCard(
                      user: user,
                      selected: selected,
                      onTap: () {
                        localSetState(() {
                          if (selected) {
                            selectedUserIds.remove(user.id);
                          } else {
                            selectedUserIds.add(user.id);
                          }
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
                        onPressed: selectedUserIds.isEmpty
                            ? null
                            : () => localSetState(() {
                                  selectedUserIds = {};
                                }),
                        child: Text(AppLocalizations.of(context)!.clearAll),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedUserIds.isEmpty
                            ? null
                            : () {
                                localSetState(() {
                                  selectedUserIds.add(getIt<User>().id);
                                  getIt<ChattingDao>().createChat(
                                    CreateChatRequest(
                                        ids: selectedUserIds.toList()),
                                  );
                                  selectedUserIds = {};
                                });
                                Navigator.of(context).pop();
                              },
                        child: Text(AppLocalizations.of(context)!.confirm),
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
      decoration: BoxDecoration(
        color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: OnepieceColors.fancyBlue.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: OnepieceColors.fancyBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.createChatting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnepieceFonts.smallHeaderStyle.copyWith(fontSize: 18),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}
