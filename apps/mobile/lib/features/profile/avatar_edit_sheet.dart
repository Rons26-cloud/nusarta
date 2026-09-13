import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/profile_repository.dart';
import '../../widgets/profile_avatar.dart';

Future<bool?> showAvatarEditSheet(BuildContext context,
    {String? avatarUrl, String displayName = ''}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        AvatarEditSheet(avatarUrl: avatarUrl, displayName: displayName),
  );
}

class AvatarEditSheet extends ConsumerStatefulWidget {
  const AvatarEditSheet(
      {super.key, required this.avatarUrl, required this.displayName});

  final String? avatarUrl;
  final String displayName;

  @override
  ConsumerState<AvatarEditSheet> createState() => _AvatarEditSheetState();
}

class _AvatarEditSheetState extends ConsumerState<AvatarEditSheet> {
  final _picker = ImagePicker();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              ProfileAvatar(
                  name: widget.displayName, url: widget.avatarUrl, radius: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Foto Profil',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, atau WebP. Maksimal 5 MB.',
                      style: TextStyle(color: AppColors.neutral, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined,
                    color: AppColors.brandEmerald),
                title: const Text('Pilih dari Galeri'),
                onTap: () => _pick(ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_camera_outlined,
                    color: AppColors.brandEmerald),
                title: const Text('Ambil Foto'),
                onTap: () => _pick(ImageSource.camera),
              ),
              if (widget.avatarUrl != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: AppColors.expense),
                  title: Text('Hapus Foto',
                      style: TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w700)),
                  onTap: _remove,
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.close_rounded),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      debugPrint('AVATAR_IMAGE_SELECTED');
      if (bytes.length > ProfileRepository.avatarMaxBytes) {
        _toast('Ukuran foto melebihi 5 MB. Pilih foto yang lebih kecil.');
        return;
      }
      final ext = _sniffFormat(bytes);
      if (ext == null) {
        _toast('Format foto tidak didukung. Gunakan JPG, PNG, atau WebP.');
        return;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Simpan Foto Profil?'),
          content: SizedBox(
            width: 220,
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () {
                  debugPrint('AVATAR_SAVE_TAPPED');
                  Navigator.pop(ctx, true);
                },
                child: const Text('Simpan')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      debugPrint('AVATAR_UPLOAD_STARTED');
      await ProfileRepository.setAvatarFromBytes(bytes, ext);
      if (!mounted) return;
      Navigator.pop(context, true);
      debugPrint('AVATAR_SHEET_CLOSED');
    } catch (error) {
      debugPrint('AVATAR_ERROR=${error.runtimeType}');
      if (mounted) {
        setState(() => _busy = false);
        _toast('Gagal mengunggah foto. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto Profil?'),
        content: const Text('Foto profil akan dihapus dari akunmu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ProfileRepository.removeAvatar();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('AVATAR_ERROR=${error.runtimeType}');
      if (mounted) {
        setState(() => _busy = false);
        _toast('Gagal menghapus foto. Coba lagi.');
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Sniffs the image container format from the first bytes so the extension
/// and MIME uploaded matches the bucket allow-list regardless of the temp
/// file name chosen by the photo picker.
String? _sniffFormat(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  return null;
}
