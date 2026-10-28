import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/image_cache_manager.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/email_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/views/user/user_detail_view.dart';
import 'package:one_piece_battles_flutter/views/user/user_profile.dart';

const _avatar = 'https://onepiece-battles.oss-cn-shanghai.aliyuncs.com/avatar';

User _user() => User(
    id: 'me',
    username: 'me@example.test',
    nickname: '路飞',
    loginRole: UserRole.NIKA,
    userRoles: [UserRole.NIKA],
    accountStatus: AccountStatus.loggedIn,
    emailVerified: true,
    imageUri: _avatar,
    profileImage: 'obsolete-invalid-base64');

class _Users extends UserDao {
  _Users() : super.empty();
  @override
  Future<User?> get(GetUserRequest request) async => _user();
}

class _Images extends ImageDao {
  _Images() : super.empty();
  final requests = <String>[];
  @override
  Future<Uint8List> loadImageBytes(String uri, {bool? fullImage}) async {
    requests.add(uri);
    return base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/0x8AAAAASUVORK5CYII=');
  }
}

void main() {
  setUp(() {
    ImageCacheManager.clear();
    GetIt.I.registerSingleton<User>(_user());
    GetIt.I.registerSingleton<Locale>(const Locale('zh'));
    GetIt.I.registerSingleton<UserDao>(_Users());
    GetIt.I.registerSingleton<ImageDao>(_Images());
    GetIt.I.registerSingleton<EmailDao>(EmailDao.empty());
  });
  tearDown(() => GetIt.I.reset());

  for (final page in [
    const UserProfile(userId: 'me'),
    const UserDetailView(userId: 'me')
  ]) {
    testWidgets(
        '${page.runtimeType} renders image_uri and ignores legacy base64',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: page),
      ));
      await tester.pumpAndSettle();
      expect((GetIt.I<ImageDao>() as _Images).requests, [_avatar]);
      expect(find.byType(ImageLazyLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
