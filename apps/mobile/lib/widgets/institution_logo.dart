import 'package:flutter/material.dart';

import '../core/branding/institution_logo_registry.dart';
import '../core/theme/app_colors.dart';

/// Institution branding is visual only and never grants provider capabilities.
class InstitutionLogo extends StatelessWidget {
  const InstitutionLogo({
    super.key,
    required this.code,
    required this.name,
    this.size = 40,
    this.borderRadius = 10,
    this.missingMarker = true,
  });

  final String code;
  final String name;
  final double size;
  final double borderRadius;
  final bool missingMarker;

  @override
  Widget build(BuildContext context) {
    final assetPath = InstitutionLogoRegistry.assetPathFor(code);
    final hasOfficial = assetPath != null;
    final logo = hasOfficial
        ? Container(
            color: InstitutionLogoRegistry.usesWhiteWordmark(code)
                ? const Color(0xFF202830)
                : Colors.white,
            padding: EdgeInsets.all(size * .08),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              semanticLabel: 'Logo $name',
              errorBuilder: (_, __, ___) =>
                  _MonogramPlaceholder(code: code, name: name),
            ),
          )
        : _MonogramPlaceholder(code: code, name: name);

    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: logo),
    );

    if (hasOfficial || !missingMarker) {
      return Semantics(image: true, label: 'Logo $name', child: tile);
    }

    return Tooltip(
      message: 'Logo resmi belum tersedia',
      child: Semantics(
        image: true,
        label: 'Logo $name (logo resmi belum tersedia)',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonogramPlaceholder extends StatelessWidget {
  const _MonogramPlaceholder({required this.code, required this.name});

  final String code;
  final String name;

  static const List<Color> _palette = [
    Color(0xFF0E6B58),
    Color(0xFF1E7660),
    Color(0xFF1E5F8A),
    Color(0xFF7A5C1E),
    Color(0xFF6B4A8A),
    Color(0xFF8A3A3A),
    Color(0xFF2A6B7A),
  ];

  String get _initial {
    final clean = name.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    if (clean.isEmpty) return code.isEmpty ? '?' : code[0];
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[
        code.codeUnits.fold<int>(0, (sum, unit) => (sum + unit).abs()) %
            _palette.length];
    return ColoredBox(
      color: color.withAlpha(30),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}
