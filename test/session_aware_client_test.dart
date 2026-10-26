import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:one_piece_battles_flutter/config/session_aware_client.dart';

void main() {
  test('only an unauthenticated response expires the active session', () async {
    var expiryCount = 0;
    final client = SessionAwareClient(
      MockClient((request) async {
        final status = int.parse(request.url.pathSegments.last);
        return http.Response('', status);
      }),
      () => expiryCount++,
    );

    await client.get(Uri.parse('https://example.test/200'));
    await client.get(Uri.parse('https://example.test/403'));
    expect(expiryCount, 0);

    final response = await client.get(Uri.parse('https://example.test/401'));
    expect(response.statusCode, 401);
    expect(expiryCount, 1);
    client.close();
  });
}
