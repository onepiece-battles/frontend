import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
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

class _CreateChattingViewState extends State<CreateChattingView> {
  TextEditingController searchFriendController = TextEditingController();
  ScrollController userListController = ScrollController();
  Set<String> selectedUserIds = {};
  List<User> users = [];

  _listUser() {
    getIt<UserDao>()
        .listFriend(
          ListFriendRequest(
            userId: getIt<User>().id,
          ),
        )
        .then(
          (value) => setState(() {
            users = value!.users;
          }),
        );
  }

  @override
  void initState() {
    super.initState();
    _listUser();
  }

  @override
  Widget build(BuildContext context) {
    return getUserSelection(context);
  }

  Widget getUserSelection(BuildContext context) {
    return StatefulBuilder(builder: (context, userSearchState) {
      return Container(
        width: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: 300,
                height: 35,
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
                    prefixIcon: const Icon(Icons.search, size: 20,),
                    labelText: AppLocalizations.of(context)!.userNameLabel,
                    labelStyle: OnepieceFonts.smallContentStyle
                  ),
                  onChanged: (value) {
                    userSearchState(() {
                      if (value.isEmpty) {
                        _listUser();
                      } else {
                        users = users
                            .where((e) => e.nickname.toLowerCase().contains(
                                searchFriendController.text.toLowerCase()))
                            .toList();
                      }
                    });
                  },
                ),
              ),
            ),

             SizedBox(
                width: 300,
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
                                        const EdgeInsets.fromLTRB(0, 3, 8, 3),
                                    child: ImageLazyLoader(
                                        key: UniqueKey(),
                                        uriProvider: () => user.imageUri!,
                                        width: 40,
                                        borderWidth: 2,
                                        borderRadios: 5),
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30.0,10,30,10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: selectedUserIds.isEmpty? null: () {
                        userSearchState(() {
                          selectedUserIds = {};
                        });
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(
                          style: OnepieceFonts.smallContentStyleWhite,
                          AppLocalizations.of(context)!.clearAll)),
                  ElevatedButton(
                      onPressed: selectedUserIds.isEmpty? null: () {
                        userSearchState(() {
                          selectedUserIds.add(getIt<User>().id);
                          getIt<ChattingDao>().createChat(
                              CreateChatRequest(ids: selectedUserIds.toList()));
                          selectedUserIds = {};
                        });
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(
                          style: OnepieceFonts.smallContentStyleWhite,
                          AppLocalizations.of(context)!.confirm))
                ],
              ),
            )
          ],
        ),
      );
    });
  }
}
