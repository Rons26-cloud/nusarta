import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared layout for legal documents (privacy policy, terms of service).
class LegalScaffold extends StatelessWidget {
  const LegalScaffold({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<({String title, List<String> paragraphs})> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Chip(
              label: Text('Pembaruan terakhir: $lastUpdated',
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.primary.withAlpha(12),
              avatar:
                  Icon(Icons.update, size: 16, color: AppColors.brandEmerald),
            ),
          ),
          const SizedBox(height: 8),
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(section.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < section.paragraphs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Text(section.paragraphs[i],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.neutral, height: 1.55)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
