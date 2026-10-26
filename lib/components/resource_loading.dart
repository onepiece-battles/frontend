import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';

class ResourceLoading extends StatelessWidget {
  const ResourceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.loading;
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 128,
            child: LinearProgressIndicator(
              minHeight: 3,
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.secondaryLabel,
              backgroundColor: OnepieceColors.surface,
              value: MediaQuery.disableAnimationsOf(context) ? .5 : null,
            ),
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: OnepieceColors.secondaryLabel))),
        ]),
      ),
    );
  }
}

class ResourceEmptyState extends StatelessWidget {
  const ResourceEmptyState({super.key, this.failed = false, this.onRetry});
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(failed ? Icons.cloud_off_outlined : Icons.search_off_rounded,
            size: 28, color: OnepieceColors.secondaryLabel),
        const SizedBox(height: 12),
        Text(failed ? loc.resourceLoadFailed : loc.noResourcesFound,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: OnepieceColors.secondaryLabel)),
        if (failed && onRetry != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(loc.retryLoading)),
        ],
      ]),
    ));
  }
}

class ResourceListBody extends StatelessWidget {
  const ResourceListBody(
      {super.key,
      required this.loading,
      required this.failed,
      required this.hasItems,
      required this.onRetry,
      required this.child});
  final bool loading;
  final bool failed;
  final bool hasItems;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (failed) return ResourceEmptyState(failed: true, onRetry: onRetry);
    if (!hasItems) {
      return loading ? const ResourceLoading() : const ResourceEmptyState();
    }
    return Stack(fit: StackFit.expand, children: [
      AbsorbPointer(absorbing: loading, child: child),
      if (loading)
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: OnepieceColors.secondaryLabel,
              backgroundColor: OnepieceColors.surface,
              semanticsLabel: AppLocalizations.of(context)!.loading,
              value: MediaQuery.disableAnimationsOf(context) ? .5 : null,
            )),
    ]);
  }
}
