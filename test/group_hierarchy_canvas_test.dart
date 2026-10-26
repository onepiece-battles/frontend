import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/group/widgets/group_hierarchy_canvas.dart';

void main() {
  testWidgets('zoom controls change scale and reset to the fitted view',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: GroupHierarchyCanvas(
            mobile: false,
            child: Text('Root group'),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);

    await tester.tap(find.byTooltip('Fit hierarchy'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
  });
}
