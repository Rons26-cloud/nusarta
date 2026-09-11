import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const splashBackground = Color(0xff063b2f);
const splashSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: splashBackground,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: splashBackground,
);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.autoContinue = true});
  final bool autoContinue;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(splashSystemUi);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (widget.autoContinue) _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: splashSystemUi,
        child: Scaffold(
          backgroundColor: splashBackground,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // The approved artwork contains the full deep-emerald background.
              // Cover keeps it edge-to-edge without stretching or added effects.
              Image.asset(
                'assets/brand/splash_screen.png',
                fit: BoxFit.cover,
                semanticLabel: 'NUSARTA. Keuanganmu, Dalam Kendalimu. '
                    'Dari Nusantara, untuk masa depan yang lebih baik.',
              ),
            ],
          ),
        ),
      );
}


