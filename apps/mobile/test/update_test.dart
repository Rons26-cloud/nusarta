import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/updates/github_release_source.dart';

void main() {
  test('compares semantic versions numerically', () {
    expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
    expect(compareVersions('1.0.9', '1.0.10'), lessThan(0));
    expect(compareVersions('1.9.9', '2.0.0'), lessThan(0));
    expect(compareVersions('2.0.0', '2.0.0'), 0);
    expect(compareVersions('2.1.0', '2.0.9'), greaterThan(0));
    expect(compareVersions('10.0.0', '2.99.99'), greaterThan(0));
    expect(compareVersions('v1.0.1', '1.0.0'), greaterThan(0));
  });
}
