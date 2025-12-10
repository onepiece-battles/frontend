import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import '../../app_router.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';

class CreateChattingView extends StatefulWidget {
  const CreateChattingView({super.key});

  @override
  State<CreateChattingView> createState() => _CreateChattingViewState();
}

Timer? _timer;

class _CreateChattingViewState extends State<CreateChattingView> {
  TextEditingController searchFriendController = TextEditingController();
  ScrollController userListController = ScrollController();
  Set<String> selectedUserIds = {getIt<User>().id};
  UserFilter userFilter = UserFilter();
  List<User> users = [];

  _listUser(String name) {
    getIt<UserDao>()
        .listUser(
          ListUsersRequest(
            pageSize: 10,
            pageIndex: 1,
            userFilter:
                UserFilter(nickname: searchFriendController.text, friend: true),
          ),
        )
        .then((value) => setState(() {
              users = value!.users;
            }));
  }
  @override
  void initState() {
    super.initState();
    _listUser("");
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 1000,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [getUserSelection(context)],
      ),
    );
  }

  Widget getSearchBar() {
    return SizedBox(
      width: 200,
      height: 35,
      child: TextFormField(
        controller: searchFriendController,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          prefixIcon: const Icon(Icons.search),
          hintText: AppLocalizations.of(context)!.name,
        ),
        onChanged: (value) {
          setState(() {
            searchFriendController.text = value;
            _listUser(value);
          });
        },
      ),
    );
  }

  Widget getUserSelection(BuildContext context) {
    return StatefulBuilder(builder: (context, userSearchState) {
      return Container(
        decoration: const BoxDecoration(
          color: OnepieceColors.liteFancyGreen,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: 400,
                height: 60,
                child: TextFormField(
                  controller: searchFriendController,
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
                          pageSize: 20,
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
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SizedBox(
                width: 400,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: userListController,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    bool isSelected = selectedUserIds.contains(user.id);
                    return Material(
                      type: MaterialType.transparency,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        child: ListTile(
                          onTap: () {
                            userSearchState(() {
                              if (isSelected) {
                                selectedUserIds.remove(user.id);
                              } else {
                                selectedUserIds.add(user.id);
                              }
                            });
                          },
                          contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          selected: selectedUserIds.contains(user.id),
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
                                        borderRadios: 6),
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
                                padding: const EdgeInsets.fromLTRB(20, 0, 3, 0),
                                child: selectedUserIds.contains(user.id)
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
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      userSearchState(() {
                        selectedUserIds = {};
                      });
                    },
                    child: Text("clear")),
                ElevatedButton(
                    onPressed: () {
                      userSearchState(() {
                        getIt<ChattingDao>().createChat(
                            CreateChatRequest(ids: selectedUserIds.toList()));
                        selectedUserIds = {};
                      });
                    },
                    child: Text("confirm"))
              ],
            )
          ],
        ),
      );
    });
  }
}
