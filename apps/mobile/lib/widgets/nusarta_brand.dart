import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';

class NusartaLogo extends StatelessWidget {
  const NusartaLogo({super.key, this.size = 76, this.dark = false});
  final double size;
  final bool dark;
  @override
  Widget build(BuildContext context) => Image.asset('assets/brand/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Logo NUSARTA');
}

class NusartaBrandHeader extends StatelessWidget {
  const NusartaBrandHeader(
      {super.key, this.title, this.subtitle, this.dark = false});
  final String? title;
  final String? subtitle;
  final bool dark;
  @override
  Widget build(BuildContext context) => Column(children: [
        NusartaLogo(size: title == null ? 104 : 44),
        const SizedBox(height: 10),
        Text('NUSARTA',
            style: TextStyle(
                fontSize: title == null ? 28 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: dark ? Colors.white : AppColors.deepEmerald)),
        const SizedBox(height: 2),
        Text(AppConfig.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: dark ? AppColors.accentLight : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        if (title != null) ...[
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(title!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: dark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800))),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(subtitle!,
                    style: TextStyle(
                        color: dark ? Colors.white70 : AppColors.neutral))),
          ],
        ],
      ]);
}

class NusartaTextField extends StatelessWidget {
  const NusartaTextField(
      {super.key,
      required this.controller,
      required this.label,
      this.icon,
      this.obscureText = false,
      this.suffixIcon,
      this.keyboardType,
      this.validator,
      this.textInputAction,
      this.onFieldSubmitted});
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  @override
  Widget build(BuildContext context) => TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          suffixIcon: suffixIcon));
}

class NusartaPrimaryButton extends StatelessWidget {
  const NusartaPrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
      onPressed: onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(label));
}

class NusartaSecondaryButton extends StatelessWidget {
  const NusartaSecondaryButton(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}

class NusartaAuthScaffold extends StatelessWidget {
  const NusartaAuthScaffold(
      {super.key,
      required this.child,
      this.onBack,
      this.artworkAsset,
      this.maskPrintedForm = true});
  final Widget child;
  final VoidCallback? onBack;
  final String? artworkAsset;
  final bool maskPrintedForm;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.deepEmerald,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (artworkAsset != null)
            Positioned.fill(
              child: Image.asset(
                artworkAsset!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.deepEmerald),
              ),
            ),
          if (artworkAsset != null && maskPrintedForm)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned(
                      top: constraints.maxHeight * .31,
                      bottom: constraints.maxHeight * .10,
                      left: 0,
                      right: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.cream.withOpacity(.97),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Stack(
              children: [
                if (onBack != null)
                  Positioned(
                    left: 8,
                    top: 4,
                    child: IconButton(
                      onPressed: onBack,
                      tooltip: 'Kembali',
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20, 96, 20, 24 + bottomInset),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
