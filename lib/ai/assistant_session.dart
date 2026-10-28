import 'package:flutter/foundation.dart';

import 'assistant_message.dart';

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

  /// Tells the listening view that [messages] or [busy] changed.
  void changed() => notifyListeners();

  void reset() {
    messages.clear();
    handledProposals.clear();
    loaded = true; // a cleared thread is "loaded" — don't refetch old history
    notifyListeners();
  }
}
