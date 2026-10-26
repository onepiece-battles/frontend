import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/components/resource_list_pagination.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';

void main() {
  for (final width in [320.0, 375.0, 1280.0]) {
    testWidgets('pagination stays aligned and works at $width', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedPage = 1;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Column(children: [
          const Spacer(),
          ResourceListPagination(
            currentPage: 1,
            totalPages: 9,
            onPageChanged: (page) => selectedPage = page,
          ),
        ])),
      ));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ResourceListPagination)).height, 38);
      expect(find.byType(PageFoot), findsOneWidget);

      final left = tester.getCenter(find.byIcon(Icons.chevron_left_rounded));
      final right = tester.getCenter(find.byIcon(Icons.chevron_right_rounded));
      final center = tester.getCenter(find.byType(TextField));
      expect((center.dx - (left.dx + right.dx) / 2).abs(), lessThan(20));
      expect(left.dy, right.dy);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(selectedPage, 2);
      await tester.enterText(find.byType(TextField), '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(selectedPage, 7);
    });
  }
}
