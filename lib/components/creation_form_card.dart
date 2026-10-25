import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';

bool validateCreationForm(GlobalKey<FormState> formKey) {
  final invalidFields = formKey.currentState!.validateGranularly();
  if (invalidFields.isEmpty) return true;
  final firstField = invalidFields.first;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (firstField.mounted) {
      Scrollable.ensureVisible(firstField.context,
          alignment: 0.15, duration: const Duration(milliseconds: 250));
    }
  });
  return false;
}

InputDecoration creationFieldDecoration(String label, {String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: OnepieceColors.separator),
  );
  return InputDecoration(
    labelText: label,
    helperText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle:
        const TextStyle(color: OnepieceColors.primaryLabel, fontSize: 14),
    floatingLabelStyle: const TextStyle(
        color: OnepieceColors.primaryLabel,
        fontSize: 14,
        fontWeight: FontWeight.w500),
    helperStyle:
        const TextStyle(color: OnepieceColors.secondaryLabel, fontSize: 12),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: OnepieceColors.fancyBlue, width: 1.5),
    ),
    errorBorder:
        border.copyWith(borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    errorMaxLines: 2,
  );
}

class CreationFormCard extends StatelessWidget {
  const CreationFormCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OnepieceColors.separator),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: OnepieceColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: OnepieceColors.secondaryLabel, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: OnepieceColors.primaryLabel,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OnepieceColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: OnepieceColors.menuIconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class CreationPageHeader extends StatelessWidget {
  const CreationPageHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: OnepieceColors.primaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
