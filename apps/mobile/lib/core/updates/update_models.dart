enum UpdateStatus { idle, checking, latest, updateAvailable, error }

class ReleaseInfo {
  const ReleaseInfo({required this.version, required this.tagName, required this.title, required this.releaseNotes, required this.publishedAt, required this.apkDownloadUrl, this.apkSize, this.isPrerelease = false});
  final String version, tagName, title, releaseNotes, publishedAt, apkDownloadUrl;
  final int? apkSize;
  final bool isPrerelease;
}

class UpdateState {
  const UpdateState(this.status, {this.release, this.message});
  final UpdateStatus status;
  final ReleaseInfo? release;
  final String? message;
}

abstract interface class UpdateSource {
  Future<ReleaseInfo?> latestStable();
}
