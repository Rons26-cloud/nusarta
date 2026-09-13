import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';
import 'auth_provider.dart';

/// Current user's `profiles` row, keyed on the auth user id so it refetches
/// on sign-in/sign-out.
final profileProvider = FutureProvider<Profile?>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return ProfileRepository.fetch();
});

/// Effective avatar URL (storage-backed avatar path first, then legacy auth
/// metadata `avatar_url` for older builds).
final profileAvatarUrlProvider = Provider<String?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final path = profile?.avatarPath;
  if (path != null && path.isNotEmpty) {
    return ProfileRepository.avatarPublicUrl(path);
  }
  final metadata =
      ref.watch(currentUserProvider)?.userMetadata?['avatar_url'] as String?;
  final uri = metadata == null ? null : Uri.tryParse(metadata);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
      ? metadata
      : null;
});
