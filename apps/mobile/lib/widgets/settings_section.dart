import 'package:flutter/material.dart';

/// Shared section hierarchy for finance and application preferences.
class SettingsSection extends StatelessWidget {
  const SettingsSection(
      {super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
            child: Text(title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
                children[i],
              ],
            ]),
          ),
        ],
      );
}
