import 'dart:convert';
import 'package:http/http.dart' as http;
import 'update_models.dart';

class TestReleaseInfo {
  const TestReleaseInfo({
    required this.version,
    required this.tagName,
    required this.apkDownloadUrl,
  });
  final String version;
  final String tagName;
  final String apkDownloadUrl;
}

final _githubApiHeaders = <String, String>{
  'Accept': 'application/vnd.github+json'
};

/// Latest prerelease tagged `test-vX.Y.Z` (testing channel), if any.
/// Mirrors `normalizeTestReleases` on web; returns null when unavailable.
Future<TestReleaseInfo?> latestTestRelease() async {
  try {
    final response = await http.Client()
        .get(Uri.parse(GithubReleaseSource.apiUrl), headers: _githubApiHeaders)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return null;
    for (final item in decoded) {
      if (item is! Map || item['draft'] == true || item['prerelease'] != true) {
        continue;
      }
      final tag = item['tag_name'];
      if (tag is! String) continue;
      final match = RegExp(r'^test-v([0-9][0-9A-Za-z.+-]*)$').firstMatch(tag);
      if (match == null) continue;
      final version = match.group(1)!;
      if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) continue;
      final assets = item['assets'];
      if (assets is! List) continue;
      final apkName = 'NUSARTA-TEST-$version.apk';
      for (final asset in assets) {
        if (asset is! Map || asset['name'] != apkName) continue;
        if (!GithubReleaseSource.isHttpsGithub(asset['browser_download_url'])) {
          continue;
        }
        return TestReleaseInfo(
          version: version,
          tagName: tag,
          apkDownloadUrl: asset['browser_download_url'] as String,
        );
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

class GithubReleaseSource implements UpdateSource {
  static const excludedReleaseTags = {'v1.0.0'};
  const GithubReleaseSource({http.Client? client}) : _client = client;
  static const apiUrl =
      'https://api.github.com/repos/Rons26-cloud/nusarta/releases';
  final http.Client? _client;

  @override
  Future<ReleaseInfo?> latestStable() async {
    final response = await (_client ?? http.Client())
        .get(Uri.parse(apiUrl), headers: _githubApiHeaders)
        .timeout(const Duration(seconds: 8));
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
              a['name'] == 'NUSARTA.apk' &&
              isHttpsGithub(a['browser_download_url']),
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

  static bool isHttpsGithub(Object? value) {
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
