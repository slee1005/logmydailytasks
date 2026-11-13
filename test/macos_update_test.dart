import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logmydailytask/integrations/macos_update.dart';

void main() {
  test('offers only a newer stable release with a Mac installer', () async {
    final release = <String, Object>{
      'tag_name': 'v0.10.0',
      'draft': false,
      'prerelease': false,
      'assets': [
        {'name': macInstallerName},
      ],
    };
    final client = MockClient((request) async {
      expect(request.url.host, 'api.github.com');
      return http.Response(jsonEncode(release), 200);
    });
    addTearDown(client.close);

    final update = await findMacUpdate(client, '0.2.0');
    expect(update?.installer.host, 'github.com');
    expect(update?.installer.pathSegments.last, macInstallerName);
    expect(await findMacUpdate(client, '0.10.0'), isNull);
    expect(await findMacUpdate(client, '1.0.0'), isNull);
    release['prerelease'] = true;
    expect(await findMacUpdate(client, '0.2.0'), isNull);
    release['prerelease'] = false;
    release['assets'] = [];
    expect(await findMacUpdate(client, '0.2.0'), isNull);
  });
}
