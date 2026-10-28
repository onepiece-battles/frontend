import 'package:flutter/material.dart';

import 'resource_loading.dart';

/// Waits for the current route's code, including when a route replaces another
/// deferred page in the same navigator slot.
class DeferredPage extends StatefulWidget {
  const DeferredPage({super.key, required this.load, required this.page});

  final Future<void> Function() load;
  final Widget Function() page;

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = widget.load();
  }

  @override
  void didUpdateWidget(covariant DeferredPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load != widget.load) _ready = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ResourceEmptyState(
                failed: true,
                onRetry: () {
                  setState(() {
                    _ready = widget.load();
                  });
                });
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const ResourceLoading();
          }
          return widget.page();
        },
      );
}
