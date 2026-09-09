import 'package:flutter/material.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.count,
    this.dotColor = Colors.white,
    this.total = 6,
  });

  final int count;
  final int total;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final filled = i < count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? dotColor : Colors.transparent,
            border: Border.all(color: dotColor, width: 1.5),
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.buttonColor = Colors.white,
    this.highlightColor = Colors.white24,
    this.keyFill,
    this.biometricColor,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final Color buttonColor;
  final Color highlightColor;
  final Color? keyFill;
  final Color? biometricColor;
  final bool enabled;

  void _press(String digit) {
    if (enabled) onDigit(digit);
  }

  @override
  Widget build(BuildContext context) {
    const rows = ['123', '456', '789'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in row.split(''))
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _KeyButton(
                    label: d,
                    color: buttonColor,
                    highlight: highlightColor,
                    fill: keyFill,
                    enabled: enabled,
                    onTap: () => _press(d),
                  ),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: _KeyButton(
                icon: onBiometric != null ? Icons.fingerprint : null,
                label: null,
                color: biometricColor ?? buttonColor,
                highlight: highlightColor,
                fill: keyFill,
                enabled: enabled && onBiometric != null,
                onTap: onBiometric,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _KeyButton(
                label: '0',
                color: buttonColor,
                highlight: highlightColor,
                fill: keyFill,
                enabled: enabled,
                onTap: () => _press('0'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                label: null,
                color: buttonColor,
                highlight: highlightColor,
                fill: keyFill,
                enabled: enabled,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.color,
    required this.highlight,
    required this.enabled,
    this.onTap,
    this.label,
    this.icon,
    this.fill,
  });

  final VoidCallback? onTap;
  final String? label;
  final IconData? icon;
  final Color color;
  final Color highlight;
  final bool enabled;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Text(
            label!,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(enabled ? 1 : 0.35),
            ),
          )
        : Icon(icon, color: color.withOpacity(enabled ? 1 : 0.35), size: 26);
    return SizedBox(
      width: 68,
      height: 68,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          highlightColor: highlight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
