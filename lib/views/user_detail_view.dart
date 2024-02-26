import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class UserDetailView extends StatefulWidget {
  final String userId;
  const UserDetailView({super.key, required this.userId});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  late User user;
  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<UserDao>().get(GetUserRequest(userId: widget.userId));
  }

  _prepareData(User user) {
    debugPrint("user ${user}");
    this.user = user;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getBasicInfo(context),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Divider(
                      color: OnepieceColors.fancyBlue,
                      thickness: 1,
                    ),
                  ),
                  _getPermissionInfo(context),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Divider(
                      color: OnepieceColors.fancyBlue,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }
      },
    );
  }

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, basicState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.basicInfo,
              style: OnepieceFonts.headerStyle,
            ),
            const SizedBox(
              width: 15,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  border: Border.all(
                      color: OnepieceColors.fancyBlue,
                      width: 5,
                      style: BorderStyle.solid),
                ),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: user.profileImage == null
                      ? Container()
                      : Image.memory(
                      Base64Helper.decode(user.profileImage!)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Text(
                AppLocalizations.of(context)!.nickname,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Text(
                user.nickname,
                style: OnepieceFonts.contentStyleBoldFancyBlue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Text(
                AppLocalizations.of(context)!.email,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.username,
                    style: OnepieceFonts.contentStyleBoldFancyBlue,
                  ),
                  Tooltip(
                    message: user.emailVerified!
                        ? AppLocalizations.of(context)!.verified
                        : AppLocalizations.of(context)!.notVerified,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: user.emailVerified!
                          ? ImageHelper.getSvgIconWithColor(
                          'images/svgs/check-circle.svg',
                          150,
                          150,
                          Colors.green)
                          : ImageHelper.getSvgIconWithColor(
                          'images/svgs/alert.svg', 150, 150, Colors.red),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getPermissionInfo(BuildContext context) {
    return Container();
  }
}
