import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _fade.forward();
    _decide();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.deepEmerald,
        body: SafeArea(
            child: FadeTransition(
          opacity: _opacity,
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 32),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/brand/logo.png',
                                  width: (constraints.maxWidth * 0.4)
                                      .clamp(100.0, 180.0),
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Logo NUSARTA'),
                              const SizedBox(height: 24),
                              const Text('NUSARTA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4)),
                              const SizedBox(height: 12),
                              const Text('Keuanganmu, Dalam Kendalimu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.cream, fontSize: 16)),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: SizedBox(
                                      width: 64,
                                      child: Divider(color: AppColors.gold))),
                              const Text(
                                  'Dari Nusantara,\nuntuk masa depan yang lebih baik.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white70, height: 1.6)),
                            ]),
                      ),
                    ),
                  )),
        )),
      );
}
