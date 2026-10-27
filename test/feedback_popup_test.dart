import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/create_feedback_popup.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';

class _IssueDaoFake extends IssueDao {
  _IssueDaoFake() : super.empty();
  CreateIssueRequest? lastRequest;

  @override
  Future<CreateIssueResponse?> createIssue(CreateIssueRequest request) async {
    lastRequest = request;
    return CreateIssueResponse(
        issueCreationResult: I18nText(zhCN: '已提交', enUS: 'Submitted'));
  }
}

Widget _app(Locale locale, ValueChanged<String> onCreated) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                      insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: CreateFeedbackPopup(onIssueCreated: onCreated))),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    GetIt.instance.registerSingleton<IssueDao>(_IssueDaoFake());
  });
  tearDown(() async => GetIt.instance.reset());

  for (final width in [320.0, 900.0]) {
    testWidgets('feedback form fits and submits at $width', (tester) async {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? result;
      await tester
          .pumpWidget(_app(const Locale('en'), (message) => result = message));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final submit = find.widgetWithText(FilledButton, 'Submit');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.tap(find.text('Bug Report'));
      await tester.enterText(
          find.byKey(const Key('feedback-title')), '  Message display issue  ');
      await tester.enterText(find.byKey(const Key('feedback-content')),
          '  The avatar edge looks too square.  ');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      final request = (GetIt.instance<IssueDao>() as _IssueDaoFake).lastRequest;
      expect(request?.issueType, IssueType.BUG_REPORT);
      expect(request?.issueHeader, 'Message display issue');
      expect(request?.issueDescription, 'The avatar edge looks too square.');
      expect(request?.issueStatus, IssueStatus.CREATED);
      expect(result, 'Submitted');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('clear resets feedback selection and content', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), (_) {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feature Suggestion'));
    await tester.enterText(
        find.byKey(const Key('feedback-title')), 'A useful idea');
    await tester.enterText(
        find.byKey(const Key('feedback-content')), 'Description');
    await tester.ensureVisible(find.text('Clear'));
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('feedback-title')))
            .controller!
            .text,
        isEmpty);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('feedback-content')))
            .controller!
            .text,
        isEmpty);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
