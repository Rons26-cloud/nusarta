import 'dart:convert';
import 'package:http/http.dart' as http;
import 'update_models.dart';

class GithubReleaseSource implements UpdateSource {
  static const excludedReleaseTags = {'v1.0.0'};
  const GithubReleaseSource({http.Client? client}) : _client = client;
  static const apiUrl =
      'https://api.github.com/repos/Rons26-cloud/nusarta/releases';
  final http.Client? _client;

  @override
  Future<ReleaseInfo?> latestStable() async {
    final response = await (_client ?? http.Client()).get(Uri.parse(apiUrl),
        headers: const {
          'Accept': 'application/vnd.github+json'
        }).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Release service unavailable');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return null;
    for (final item in decoded) {
      if (item is! Map || item['draft'] == true || item['prerelease'] == true) {
        continue;
      }
      final tag = item['tag_name'];
      if (tag is String && excludedReleaseTags.contains(tag)) continue;
      final version = _normalizeVersion(tag);
      if (version == null || item['published_at'] is! String) continue;
      final assets = item['assets'];
      if (assets is! List) continue;
      final apk = assets.whereType<Map>().cast<Map>().firstWhere(
          (a) =>
              a['name'] == 'NUSARTA.apk' && _isHttps(a['browser_download_url']),
          orElse: () => <String, dynamic>{});
      if (apk.isEmpty) continue;
      return ReleaseInfo(
          version: version,
          tagName: tag as String,
          title: (item['name'] as String?) ?? 'NUSARTA v$version',
          releaseNotes: (item['body'] as String?) ?? '',
          publishedAt: item['published_at'] as String,
          apkDownloadUrl: apk['browser_download_url'] as String,
          apkSize: apk['size'] as int?);
    }
    return null;
  }

  static String? _normalizeVersion(Object? tag) {
    if (tag is! String) return null;
    final value = tag.replaceFirst(RegExp(r'^v', caseSensitive: false), '');
    return RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value) ? value : null;
  }

  static bool _isHttps(Object? value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    return uri?.scheme == 'https' && uri?.host == 'github.com';
  }
}

int compareVersions(String left, String right) {
  final a = left
      .replaceFirst(RegExp(r'^v', caseSensitive: false), '')
      .split('.')
      .map(int.parse)
      .toList();
  final b = right
      .replaceFirst(RegExp(r'^v', caseSensitive: false), '')
      .split('.')
      .map(int.parse)
      .toList();
  for (var i = 0; i < 3; i++) {
    final result = a[i].compareTo(b[i]);
    if (result != 0) return result;
  }
  return 0;
}
