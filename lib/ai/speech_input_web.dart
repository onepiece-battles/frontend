import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Thin wrapper over the browser Web Speech API (`webkitSpeechRecognition`).
/// Everything is defensive: if the API is missing or throws, [isSupported] is
/// false / [onError] fires, and the UI simply hides the mic.
class SpeechInput {
  JSObject? _recognition;

  bool get isSupported =>
      globalContext.has('webkitSpeechRecognition') ||
      globalContext.has('SpeechRecognition');

  void start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
    String lang = 'zh-CN',
  }) {
    try {
      final ctor = (globalContext.getProperty('webkitSpeechRecognition'.toJS) ??
          globalContext.getProperty('SpeechRecognition'.toJS)) as JSFunction?;
      if (ctor == null) {
        onError('unsupported');
        return;
      }
      final rec = ctor.callAsConstructor<JSObject>();
      _recognition = rec;
      rec.setProperty('lang'.toJS, lang.toJS);
      rec.setProperty('interimResults'.toJS, false.toJS);
      rec.setProperty('continuous'.toJS, false.toJS);
      rec.setProperty('maxAlternatives'.toJS, 1.toJS);

      rec.setProperty(
          'onresult'.toJS,
          ((JSObject event) {
            try {
              final results = event.getProperty<JSObject>('results'.toJS);
              final length =
                  results.getProperty<JSNumber>('length'.toJS).toDartInt;
              if (length == 0) return;
              final last = results.getProperty<JSObject>('${length - 1}'.toJS);
              final alt = last.getProperty<JSObject>('0'.toJS);
              final transcript =
                  alt.getProperty<JSString>('transcript'.toJS).toDart;
              onResult(transcript);
            } catch (e) {
              onError('$e');
            }
          }).toJS);

      rec.setProperty(
          'onerror'.toJS,
          ((JSObject event) {
            final err = event.getProperty('error'.toJS);
            onError(err == null ? 'error' : err.toString());
          }).toJS);

      rec.setProperty('onend'.toJS, (() => onEnd()).toJS);

      rec.callMethod('start'.toJS);
    } catch (e) {
      onError('$e');
    }
  }

  void stop() {
    try {
      _recognition?.callMethod('stop'.toJS);
    } catch (_) {}
  }
}
