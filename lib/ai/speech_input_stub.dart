/// Voice input is only available on the web build; this stub is selected on
/// other platforms so the app still compiles.
class SpeechInput {
  bool get isSupported => false;

  void start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
    String lang = 'zh-CN',
  }) =>
      onError('unsupported');

  void stop() {}
}
