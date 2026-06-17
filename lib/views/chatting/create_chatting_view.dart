import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';

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
                    decoration: _searchDecoration(
                        context, AppLocalizations.of(context)!.userNameLabel),
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
                    return _buildUserCard(
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

  InputDecoration _searchDecoration(BuildContext context, String label) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: OnepieceColors.menuHoverColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: OnepieceColors.menuHoverColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: OnepieceColors.fancyGreen, width: 2),
      ),
      prefixIcon: const Icon(Icons.search, size: 19),
      labelText: label,
      labelStyle: OnepieceFonts.smallContentStyle,
    );
  }

  Widget _buildUserCard({
    required User user,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: selected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? OnepieceColors.liteFancyBlue.withValues(alpha: 0.7)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? OnepieceColors.fancyBlue.withValues(alpha: 0.35)
              : OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: OnepieceColors.liteFancyBlue,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ImageLazyLoader(
                  key: ValueKey(user.imageUri),
                  uriProvider: () => user.imageUri ?? '',
                  width: 40,
                  borderWidth: 1.5,
                  borderRadios: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnepieceFonts.contentStyle
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.menuIconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
