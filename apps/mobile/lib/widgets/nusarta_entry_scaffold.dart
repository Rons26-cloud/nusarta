import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Clips login/register artwork to decoration, excluding every printed input.
class NusartaEntryScaffold extends StatelessWidget {
  const NusartaEntryScaffold({
    super.key,
    required this.artworkAsset,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
    this.footerFraction = .08,
  });

  final String artworkAsset;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;
  final double footerFraction;

  Widget _artworkSlice(Alignment alignment, double fraction) =>
      ExcludeSemantics(
        child: ClipRect(
          child: Align(
            alignment: alignment,
            heightFactor: fraction,
            child: Image.asset(artworkAsset,
                width: double.infinity, fit: BoxFit.fitWidth),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.deepEmerald,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: ColoredBox(
            color: AppColors.cream,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Stack(
                            children: [
                              _artworkSlice(Alignment.topCenter, .29),
                              Positioned(
                                left: 8,
                                top: 4,
                                child: IconButton(
                                  onPressed: onBack,
                                  tooltip: 'Kembali',
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 18, 20, 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(title,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text(subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 22),
                                    child,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _artworkSlice(Alignment.bottomCenter, footerFraction),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
