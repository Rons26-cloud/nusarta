import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nusarta/core/updates/github_release_source.dart';

Map<String, Object?> release(String tag,
        {bool draft = false, bool prerelease = false, bool apk = true}) =>
    {
      'tag_name': tag,
      'draft': draft,
      'prerelease': prerelease,
      'name': 'NUSARTA $tag',
      'body': 'Stable release notes',
      'published_at': '2026-09-09T10:00:00Z',
      'assets': [
        if (apk)
          {
            'name': 'NUSARTA.apk',
            'browser_download_url':
                'https://github.com/Rons26-cloud/nusarta/releases/download/$tag/NUSARTA.apk',
            'size': 52428800,
          }
      ],
    };

void main() {
  test('website release asset contract remains compatible with mobile updates',
      () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), GithubReleaseSource.apiUrl);
      return http.Response(
          jsonEncode([release('v1.0.4'), release('v1.0.3')]), 200);
    });
    addTearDown(client.close);
    final latest = await GithubReleaseSource(client: client).latestStable();
    expect(latest?.version, '1.0.4');
    expect(latest?.apkDownloadUrl,
        'https://github.com/Rons26-cloud/nusarta/releases/download/v1.0.4/NUSARTA.apk');
    expect(latest?.apkSize, 52428800);
  });

  test('mobile ignores drafts, prereleases and releases without the APK',
      () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode([
          release('v3.0.0', draft: true),
          release('v2.0.0', prerelease: true),
          release('v1.0.5-beta.1'),
          release('v1.0.5', apk: false),
          release('v1.0.4'),
        ]),
        200));
    addTearDown(client.close);
    expect((await GithubReleaseSource(client: client).latestStable())?.version,
        '1.0.4');
  });

  test('mobile excludes the confirmed broken release', () async {
    final client = MockClient(
        (_) async => http.Response(jsonEncode([release('v1.0.0')]), 200));
    addTearDown(client.close);
    expect(await GithubReleaseSource(client: client).latestStable(), isNull);
  });

  test('mobile handles an empty stable history', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    expect(await GithubReleaseSource(client: client).latestStable(), isNull);
  });

  test('mobile surfaces GitHub failure instead of inventing an update',
      () async {
    final client = MockClient((_) async => http.Response('Unavailable', 503));
    addTearDown(client.close);
    await expectLater(
        GithubReleaseSource(client: client).latestStable(), throwsException);
  });
}
