import 'dart:convert';

/// One `text/event-stream` event whose data is a JSON object.
typedef JsonEvent = ({String name, Map<String, dynamic> data});

/// Parses a `text/event-stream` body into named JSON events. The bytes may be
/// split anywhere — mid-line or mid-character — so decoding is incremental.
/// Events whose data is not a JSON object are skipped.
Stream<JsonEvent> parseJsonEvents(Stream<List<int>> body) async* {
  String? event;
  final data = <String>[];
  await for (final line
      in body.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final parsed = _decode(event, data);
      if (parsed != null) yield parsed;
      event = null;
      data.clear();
    } else if (!line.startsWith(':')) {
      // Lines starting with ":" are comments / keep-alives.
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') {
        event = value;
      } else if (field == 'data') {
        data.add(value);
      }
    }
  }
  // Tolerate a last event that is not followed by a blank line.
  final parsed = _decode(event, data);
  if (parsed != null) yield parsed;
}

JsonEvent? _decode(String? event, List<String> data) {
  if (data.isEmpty) return null;
  try {
    final json = jsonDecode(data.join('\n'));
    return json is Map<String, dynamic>
        ? (name: event ?? 'message', data: json)
        : null;
  } on FormatException {
    return null;
  }
}
