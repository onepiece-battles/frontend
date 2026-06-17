import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../repository/user_dao.dart';

Timer? _timer;

class AddFriendView extends StatefulWidget {
  const AddFriendView({super.key});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final TextEditingController searchUserController = TextEditingController();
  final ScrollController userListController = ScrollController();
  List<User> users = [];
  String selectedUserId = "";
  UserFilter userFilter = UserFilter();

  @override
  void dispose() {
    _timer?.cancel();
    searchUserController.dispose();
    userListController.dispose();
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
                    controller: searchUserController,
                    decoration: _searchDecoration(
                        context, AppLocalizations.of(context)!.userNameLabel),
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
                        getIt<UserDao>()
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
                    return _buildUserCard(
                      user: user,
                      selected: isSelected,
                      disabled: isMe,
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
                                getIt<UserDao>()
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
            child: const Icon(Icons.group_add_outlined,
                color: OnepieceColors.fancyBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.addFriend,
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
    );
  }

  Widget _buildUserCard({
    required User user,
    required bool selected,
    required bool disabled,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: selected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: disabled
          ? OnepieceColors.menuHoverColor.withValues(alpha: 0.25)
          : selected
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
        hoverColor:
            disabled ? Colors.transparent : OnepieceColors.liteFancyBlue,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ImageLazyLoader(
                  key: ValueKey(user.imageUri),
                  uriProvider: () => user.imageUri ?? '',
                  width: 42,
                  borderWidth: 1.5,
                  borderRadios: 42),
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
