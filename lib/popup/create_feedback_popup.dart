import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';
import '../repository/issue_dao.dart';
import '../utils/i18n_helper.dart';
import 'onepiece_alert.dart';

GetIt getIt = GetIt.instance;

class CreateFeedbackPopup extends StatefulWidget {
  final ValueChanged<String>? onIssueCreated;

  const CreateFeedbackPopup({super.key, this.onIssueCreated});

  @override
  State<CreateFeedbackPopup> createState() => _CreateFeedbackPopupState();
}

class _CreateFeedbackPopupState extends State<CreateFeedbackPopup> {
  IssueType? selectedIssueType;
  final TextEditingController headerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isSubmitting = false;

  bool get _hasContent =>
      selectedIssueType != null ||
      headerController.text.isNotEmpty ||
      descriptionController.text.isNotEmpty;

  bool get _canSubmit =>
      !_isSubmitting &&
      selectedIssueType != null &&
      headerController.text.trim().isNotEmpty &&
      descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    headerController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typeNames = <IssueType, String>{
      IssueType.BUG_REPORT: loc.bugReport,
      IssueType.FEATURE_SUGGESTION: loc.featureSuggestion,
      IssueType.OTHER: loc.otherType,
    };
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: size.width < 520 ? size.width - 32 : 460,
        maxHeight: size.height - 48,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            size.width < 400 ? 20 : 26, 24, size.width < 400 ? 20 : 26, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: OnepieceColors.surface, shape: BoxShape.circle),
                child: const Icon(Icons.rate_review_outlined,
                    color: OnepieceColors.fancyBlue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.feedback,
                          style: const TextStyle(
                              fontSize: 22,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.primaryLabel)),
                      const SizedBox(height: 4),
                      Text(loc.feedbackSubtitle,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: OnepieceColors.secondaryLabel)),
                    ]),
              ),
              IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      size: 19, color: OnepieceColors.secondaryLabel)),
            ]),
            const SizedBox(height: 24),
            _label(loc.issueType),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in [
                  IssueType.BUG_REPORT,
                  IssueType.FEATURE_SUGGESTION,
                  IssueType.OTHER
                ])
                  _typeChoice(type, typeNames[type]!),
              ],
            ),
            const SizedBox(height: 22),
            _label(loc.feedbackTitle),
            const SizedBox(height: 8),
            TextField(
              key: const Key('feedback-title'),
              controller: headerController,
              enabled: !_isSubmitting,
              maxLength: 30,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontSize: 15, color: OnepieceColors.primaryLabel),
              decoration: _decoration(loc.feedbackTitleHint),
            ),
            const SizedBox(height: 8),
            _label(loc.feedbackContent),
            const SizedBox(height: 8),
            TextField(
              key: const Key('feedback-content'),
              controller: descriptionController,
              enabled: !_isSubmitting,
              minLines: 5,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: OnepieceColors.primaryLabel),
              decoration: _decoration(loc.feedbackContentHint),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final clear = TextButton(
                onPressed: !_hasContent || _isSubmitting
                    ? null
                    : () {
                        headerController.clear();
                        descriptionController.clear();
                        setState(() => selectedIssueType = null);
                      },
                child: Text(loc.clearAll),
              );
              final submit = FilledButton(
                onPressed: _canSubmit ? _submitIssue : null,
                style: FilledButton.styleFrom(
                  backgroundColor: OnepieceColors.fancyBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(112, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(loc.submitForm),
              );
              if (constraints.maxWidth < 280) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: double.infinity, child: submit),
                      Align(alignment: Alignment.centerRight, child: clear),
                    ]);
              }
              return Row(children: [clear, const Spacer(), submit]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: OnepieceColors.primaryLabel));

  Widget _typeChoice(IssueType type, String label) {
    final selected = selectedIssueType == type;
    return Material(
      color: selected
          ? OnepieceColors.fancyBlue.withValues(alpha: .09)
          : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
            color:
                selected ? OnepieceColors.fancyBlue : OnepieceColors.separator),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _isSubmitting
            ? null
            : () => setState(() => selectedIssueType = type),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[
              const Icon(Icons.check,
                  size: 15, color: OnepieceColors.fancyBlue),
              const SizedBox(width: 5),
            ],
            Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? OnepieceColors.fancyBlue
                            : OnepieceColors.primaryLabel))),
          ]),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 14, color: OnepieceColors.secondaryLabel),
        filled: true,
        fillColor: OnepieceColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        counterStyle:
            const TextStyle(fontSize: 11, color: OnepieceColors.secondaryLabel),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: OnepieceColors.fancyBlue, width: 1)),
      );

  Future<void> _submitIssue() async {
    if (!_canSubmit) return;
    final loc = AppLocalizations.of(context)!;
    final showAlert = OnepieceAlert.createAlertShower(context);
    setState(() => _isSubmitting = true);

    try {
      final response = await getIt<IssueDao>().createIssue(CreateIssueRequest(
        issueHeader: headerController.text.trim(),
        issueDescription: descriptionController.text.trim(),
        issueStatus: IssueStatus.CREATED,
        issueType: selectedIssueType,
      ));
      if (!mounted) return;
      if (response == null) throw StateError('Feedback submission failed');
      Navigator.of(context).pop();
      widget.onIssueCreated?.call(
          I18nHelper.getDisplayNameFromI18n(response.issueCreationResult));
    } catch (_) {
      if (!mounted) return;
      showAlert(loc.hint, loc.battleStatusFailed);
      setState(() => _isSubmitting = false);
    }
  }
}
