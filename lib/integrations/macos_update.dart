import 'dart:convert';

import 'package:http/http.dart' as http;

const macReleaseVersion = String.fromEnvironment('WORKLOG_RELEASE_VERSION');
const macInstallerName = 'LogMyDailyTask-macOS.dmg';
const _repository = 'slee1005/logmydailytasks';
final _versionPattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$');

Future<({String version, Uri installer})?> findMacUpdate(
  http.Client client,
  String installed,
) async {
  final response = await client
      .get(Uri.https('api.github.com', '/repos/$_repository/releases/latest'))
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) return null;
  final release = jsonDecode(response.body) as Map<String, dynamic>;
  final tag = release['tag_name'] as String;
  final latest = _versionPattern.firstMatch(tag);
  final current = _versionPattern.firstMatch(installed);
  if (latest == null || current == null || !_isNewer(latest, current)) {
    return null;
  }
  if (release['draft'] != false || release['prerelease'] != false) return null;
  final assets = release['assets'] as List<dynamic>;
  if (!assets.any((asset) => asset['name'] == macInstallerName)) return null;
  return (
    version: tag,
    installer: Uri.https(
      'github.com',
      '/$_repository/releases/download/$tag/$macInstallerName',
    ),
  );
}

bool _isNewer(RegExpMatch latest, RegExpMatch current) {
  for (var part = 1; part <= 3; part++) {
    final difference = int.parse(latest[part]!) - int.parse(current[part]!);
    if (difference != 0) return difference > 0;
  }
  return false;
}
