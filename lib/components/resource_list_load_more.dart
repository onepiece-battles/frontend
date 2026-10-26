import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';

/// A reserved row at the end of a scrolling roster. New items are appended
/// above it, so the current scroll position never jumps when a page arrives.
class ResourceListLoadMore extends StatelessWidget {
  const ResourceListLoadMore({
    super.key,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: 52,
      child: Center(
        child: failed
            ? TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(loc.retryLoading),
              )
            : loading
                ? SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(3),
                      color: OnepieceColors.secondaryLabel,
                      backgroundColor: OnepieceColors.surface,
                      semanticsLabel: loc.loading,
                      value:
                          MediaQuery.disableAnimationsOf(context) ? .5 : null,
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
