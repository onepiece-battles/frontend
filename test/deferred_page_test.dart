import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/components/deferred_page.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';

Widget _app(Widget page) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: page),
    );

void main() {
  testWidgets('reused deferred page waits for the next library',
      (tester) async {
    final first = Completer<void>();
    final second = Completer<void>();
    await tester.pumpWidget(_app(DeferredPage(
        load: () => first.future, page: () => const Text('Character'))));
    first.complete();
    await tester.pump();
    expect(find.text('Character'), findsOneWidget);
    var builtSecond = false;
    await tester.pumpWidget(_app(DeferredPage(
        load: () => second.future,
        page: () {
          builtSecond = true;
          return const Text('Battle');
        })));
    expect(builtSecond, isFalse);
    second.complete();
    await tester.pump();
    expect(find.text('Battle'), findsOneWidget);
  });

  testWidgets('failed deferred download retries the current route',
      (tester) async {
    var requests = 0;
    await tester.pumpWidget(_app(DeferredPage(
      load: () async {
        if (++requests == 1) throw StateError('temporary network error');
      },
      page: () => const Text('Loaded'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Loaded'), findsOneWidget);
    expect(requests, 2);
  });
}
