import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Renders a user photo if available, otherwise a letter avatar.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 25,
    this.lightBackground = false,
  });

  final String name;
  final String? url;
  final double radius;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? 'N' : name.trim().substring(0, 1).toUpperCase();
    final background =
        lightBackground ? AppColors.cream : AppColors.primary.withAlpha(25);
    final foreground =
        lightBackground ? AppColors.primaryDark : AppColors.primary;
    final url = this.url;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: url != null
          ? ClipOval(
              child: Image.network(
                key: ValueKey(url),
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: radius,
                  backgroundColor: background,
                  child: Text(initial,
                      style: TextStyle(
                          color: foreground,
                          fontSize: radius * 0.7,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            )
          : CircleAvatar(
              radius: radius,
              backgroundColor: background,
              child: Text(initial,
                  style: TextStyle(
                      color: foreground,
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.w800)),
            ),
    );
  }
}
