import 'deepseek_service.dart';

/// Holds the live AI conversation for the whole app session (one per login),
/// so navigating to a resource and back — which rebuilds the assistant view —
/// keeps the running transcript and on-screen messages instead of resetting
/// context every time. Registered as a GetIt singleton in ApiInitializer.
class AssistantSession {
  final DeepSeekAssistant assistant = DeepSeekAssistant();
  final List<AiChatMessage> messages = [];

  /// Messages whose battle-proposal card has already been confirmed/cancelled.
  final Set<AiChatMessage> handledProposals = {};

  /// Whether history has been loaded from the backend this session.
  bool loaded = false;

  void reset() {
    assistant.reset();
    messages.clear();
    handledProposals.clear();
    loaded = true; // a cleared thread is "loaded" — don't refetch old history
  }
}
