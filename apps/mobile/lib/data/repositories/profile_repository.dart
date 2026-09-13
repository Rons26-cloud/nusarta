import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/data/supabase_client.dart';
import '../models/profile.dart';

/// Handles the public `profiles` row and the `avatars` storage bucket.
///
/// Security model: the bucket is public only for reads; writes are confined
/// by RLS to the caller's own `<uid>/` folder (migration 009) plus a 5 MB
/// size limit and JPEG/PNG/WebP MIME allow-list enforced at the bucket level.
class ProfileRepository {
  ProfileRepository._();

  static const table = 'profiles';
  static const avatarBucket = 'avatars';
  static const avatarMaxBytes = 5 * 1024 * 1024;

  static Future<Profile?> fetch() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;
    final row = await SupabaseConfig.client
        .from(table)
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  /// Absolute URL for a stored avatar path (no request is made — it is
  /// derived from the public bucket's base URL).
  static String avatarPublicUrl(String path) =>
      SupabaseConfig.client.storage.from(avatarBucket).getPublicUrl(path);

  /// Uploads avatar bytes under `<uid>/<timestamp>.<ext>`, updates the profile
  /// row, and deletes the previous file (if any) so replacements never leave
  /// orphans.
  static Future<String> setAvatarFromBytes(
      Uint8List bytes, String extension) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    if (bytes.isEmpty) throw ArgumentError('Avatar bytes are empty');
    if (bytes.length > avatarMaxBytes) {
      throw ArgumentError('Avatar exceeds 5 MB');
    }

    final ext = extension.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) {
      throw ArgumentError('Unsupported avatar format');
    }

    final previous = await _currentAvatarPath(user.id);
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await SupabaseConfig.client.storage.from(avatarBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _mimeFor(ext),
              upsert: false,
              cacheControl: '3600',
            ),
          );
      debugPrint('AVATAR_UPLOAD_SUCCESS');

      debugPrint('AVATAR_PROFILE_UPDATE_STARTED');
      final updated = await SupabaseConfig.client
          .from(table)
          .update({
            'avatar_path': path,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id)
          .select('id, avatar_path')
          .maybeSingle();
      debugPrint('AVATAR_PROFILE_UPDATE_SUCCESS');
      if (updated == null || updated['avatar_path'] != path) {
        throw StateError('Profile avatar row was not updated');
      }

      if (previous != null && previous != path) {
        await _removePath(previous);
      }
      return path;
    } catch (error) {
      debugPrint('AVATAR_ERROR=${error.runtimeType}');
      try {
        await SupabaseConfig.client.storage.from(avatarBucket).remove([path]);
      } catch (cleanupError) {
        debugPrint('AVATAR_CLEANUP_ERROR=${cleanupError.runtimeType}');
      }
      rethrow;
    }
  }

  static Future<void> removeAvatar() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final previous = await _currentAvatarPath(user.id);
    if (previous == null) return;

    final updated = await SupabaseConfig.client
        .from(table)
        .update({
          'avatar_path': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id)
        .select('id, avatar_path')
        .maybeSingle();
    if (updated == null || updated['avatar_path'] != null) {
      throw StateError('Profile avatar row was not cleared');
    }
    await _removePath(previous);
  }

  static Future<void> _removePath(String path) async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null || !path.startsWith('$uid/')) return;
    try {
      await SupabaseConfig.client.storage.from(avatarBucket).remove([path]);
    } catch (error) {
      debugPrint('AVATAR_CLEANUP_ERROR=${error.runtimeType}');
    }
  }

  static Future<void> updateDisplayName(String name) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    await SupabaseConfig.client.from(table).update({
      'display_name': name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
  }

  static Future<String?> _currentAvatarPath(String userId) async {
    final row = await SupabaseConfig.client
        .from(table)
        .select('avatar_path')
        .eq('id', userId)
        .maybeSingle();
    final value = row?['avatar_path'] as String?;
    return (value == null || value.trim().isEmpty) ? null : value;
  }

  static String _mimeFor(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
