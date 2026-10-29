import 'package:flutter/foundation.dart';

import 'assistant_message.dart';
import 'assistant_events.dart';

/// Holds the AI conversation for the whole app session (one per login), so
/// navigating to a resource and back — which rebuilds the assistant view —
/// keeps the on-screen messages, including an answer that is still streaming
/// in: the stream keeps updating this session and whichever view is showing
/// it listens. The model's context itself lives on the server.
/// Registered as a GetIt singleton in ApiInitializer.
class AssistantSession extends ChangeNotifier {
  final List<AiChatMessage> messages = [];

  /// Messages whose battle-proposal card has already been confirmed/cancelled.
  final Set<AiChatMessage> handledProposals = {};

  /// Whether history has been loaded from the backend this session.
  bool loaded = false;

  /// An answer is streaming in; the next question waits for it.
  bool busy = false;

  /// Retained for this login session when the assistant view is rebuilt.
  /// Null means its first opening: start at the latest message.
  double? scrollOffset;
  bool followLatest = true;

  /// Keep every displayed copy in sync with the server's result, including
  /// earlier messages reached by scrolling back after confirming/cancelling.
  Set<String> applyActionUpdates(List<AiActionProposal> proposals) {
    final byCode = {for (final p in proposals) p.code: p};
    final updated = <String>{};
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.actionProposals.any((p) => byCode.containsKey(p.code))) {
        continue;
      }
      final next = message.withActionProposals(message.actionProposals.map((p) {
        final replacement = byCode[p.code];
        if (replacement != null) updated.add(p.code);
        return replacement ?? p;
      }).toList());
      messages[i] = next;
      if (handledProposals.remove(message)) handledProposals.add(next);
    }
    return updated;
  }

  /// Keep the stored/wire command exact while presenting a readable user action.
  String displayCommand(String text, {required bool zh}) {
    final command = RegExp(
            r'^(确认|取消|confirm|cancel)\s+([A-Fa-f0-9]{10})[。.!！]?$',
            caseSensitive: false)
        .firstMatch(text.trim());
    if (command == null) return text;
    final code = command.group(2)!.toUpperCase();
    for (final proposal in messages.expand((m) => m.actionProposals)) {
      if (proposal.code != code) continue;
      final cancel =
          const ['取消', 'cancel'].contains(command.group(1)!.toLowerCase());
      final verb = cancel ? (zh ? '取消' : 'Cancel') : (zh ? '确认' : 'Confirm');
      return '$verb：${proposal.title}';
    }
    return text;
  }

  /// Tells the listening view that [messages] or [busy] changed.
  void changed() => notifyListeners();

  void reset() {
    messages.clear();
    scrollOffset = null;
    followLatest = true;
    handledProposals.clear();
    loaded = true; // a cleared thread is "loaded" — don't refetch old history
    notifyListeners();
  }
}
