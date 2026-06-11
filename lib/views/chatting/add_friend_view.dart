import 'dart:async';

import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/user_dao.dart';
import '../../l10n/app_localizations.dart';

Timer? _timer;

class AddFriendView extends StatefulWidget {
  const AddFriendView({super.key});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  TextEditingController searchUserController = TextEditingController();
  ScrollController userListController = ScrollController();
  List<User> users = [];
  String selectedUserId = "";
  UserFilter userFilter = UserFilter();

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, userSearchState) {
      return Container(
        width: 450,
        decoration: const BoxDecoration(
          color: OnepieceColors.liteFancyGreen,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              SizedBox(
                width: 400,
                height: 60,
                child: TextFormField(
                  controller: searchUserController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search),
                    labelText: AppLocalizations.of(context)!.userNameLabel,
                  ),
                  onChanged: (value) {
                    if (_timer?.isActive ?? false) _timer?.cancel();
                    _timer = Timer(const Duration(milliseconds: 500), () {
                      userFilter.nickname = value;
                      ListUsersRequest listUserRequest = ListUsersRequest(
                          pageSize: 5,
                          pageIndex: 1,
                          // do not need to sort in this case.
                          sortKeys: [],
                          userFilter: userFilter);
                      Future<ListUsersResponse?> listUserResponse =
                          getIt<UserDao>().listUser(listUserRequest);
                      listUserResponse.then((value) {
                        userSearchState(() {
                          users = value!.users;
                        });
                      });
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: SizedBox(
                  width: 400,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: userListController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      bool isSelected = selectedUserId == user.id;
                      return Material(
                        type: MaterialType.transparency,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: ListTile(
                            onTap: user.id==getIt<User>().id? null: () {
                              userSearchState(() {
                                if (isSelected) {
                                  selectedUserId = "";
                                } else {
                                  selectedUserId = user.id;
                                }
                              });
                            },
                            contentPadding:
                                const EdgeInsets.fromLTRB(8, 0, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            selected: selectedUserId == user.id,
                            hoverColor: OnepieceColors.fancyBlue,
                            selectedTileColor: OnepieceColors.fancyBlue,
                            tileColor: Colors.black54,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(3, 3, 8, 3),
                                      child: ImageLazyLoader(
                                          key: UniqueKey(),
                                          uriProvider: () => user.imageUri!,
                                          width: 50,
                                          borderWidth: 2,
                                          borderRadios: 50),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.nickname,
                                            style: OnepieceFonts
                                                .smallContentStyleWhite),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 3, 0),
                                  child: selectedUserId == user.id
                                      ? const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                        )
                                      : const Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: selectedUserId == ""
                            ? null
                            : () {
                                userSearchState(() {
                                  selectedUserId = "";
                                });
                              },
                        child: Text(AppLocalizations.of(context)!.cancelPopUp)),
                    ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: selectedUserId == ""
                            ? null
                            : () {
                                final navigator = Navigator.of(context);
                                userSearchState(() {
                                  getIt<UserDao>()
                                      .addFriend(AddFriendRequest(
                                          friendId: selectedUserId))
                                      .then((value) {
                                    if (value!.result!) {
                                      selectedUserId = "";
                                    }
                                    navigator.pop();
                                  });
                                });
                              },
                        child: Text(AppLocalizations.of(context)!.submitForm))
                  ],
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
