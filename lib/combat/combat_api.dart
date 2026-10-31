import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

class CombatSkill {
  CombatSkill(this.data);
  final Map<String, dynamic> data;
  String name(bool zh) =>
      '${data[zh ? 'name' : 'englishName'] ?? data['name'] ?? ''}';
  int get energy => (data['energy'] as num?)?.toInt() ?? 0;
  int get cooldown => (data['cooldown'] as num?)?.toInt() ?? 0;
  int get maxUses => (data['maxUses'] as num?)?.toInt() ?? 0;
  String get target => '${data['target'] ?? ''}';
  String get origin => '${data['origin'] ?? ''}';
  List<Map<String, dynamic>> get effects =>
      ((data['effects'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
}

class CombatProfile {
  CombatProfile(this.data);
  final Map<String, dynamic> data;
  int get version => (data['version'] as num?)?.toInt() ?? 1;
  int get coating => (data['coatingLevel'] as num?)?.toInt() ?? 0;
  String get era => '${data['era'] ?? ''}';
  List<CombatSkill> get skills => ((data['skills'] as List?) ?? const [])
      .whereType<Map>()
      .map((e) => CombatSkill(Map<String, dynamic>.from(e)))
      .toList();
}

class CombatEvent {
  CombatEvent(this.data);
  final Map<String, dynamic> data;
  int get round => (data['round'] as num?)?.toInt() ?? 0;
  String get label => '${data['label'] ?? ''}';
  String get actor => '${data['actor'] ?? ''}';
  bool get missed => data['missed'] == true;
  List<Map<String, dynamic>> get effects =>
      ((data['effects'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
}

class CombatRecord {
  CombatRecord(Map<String, dynamic> data)
      : snapshot =
            Map<String, dynamic>.from(data['snapshot'] as Map? ?? const {}),
        events = ((data['events'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => CombatEvent(Map<String, dynamic>.from(e)))
            .toList();
  final Map<String, dynamic> snapshot;
  final List<CombatEvent> events;
}

/// Uses the shared JWT and session-expiry client; old servers may omit the additive endpoints.
class CombatApi {
  CombatApi(this.client);
  final ApiClient client;
  Future<Map<String, dynamic>?> _get(String path) async {
    final headers = <String, String>{'Accept': 'application/json'};
    await client.authentication?.applyToParams(<QueryParam>[], headers);
    final result = await client.client.send(http.Request(
        'GET', Uri.parse('${client.basePath}/api/onepiece/combat$path'))
      ..headers.addAll(headers));
    if (result.statusCode == 404) {
      await result.stream.drain<void>();
      return null;
    }
    final body = await result.stream.bytesToString();
    if (result.statusCode >= 400) throw ApiException(result.statusCode, body);
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  }

  Future<CombatProfile?> profile(String id) async {
    final data = await _get('/characters/${Uri.encodeComponent(id)}');
    return data == null ? null : CombatProfile(data);
  }

  Future<CombatRecord?> record(String id) async {
    final data = await _get('/battles/${Uri.encodeComponent(id)}');
    return data == null || data['snapshot'] == null ? null : CombatRecord(data);
  }
}
