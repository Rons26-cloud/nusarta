import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const splashBackground = Color(0xff063b2f);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _setSplashSystemUi();
    _continue();
  }

  void _setSplashSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: splashBackground,
      systemNavigationBarColor: splashBackground,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: splashBackground,
    ));
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: splashBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            const imageAspect = 887 / 1774;
            final viewportAspect = constraints.maxWidth / constraints.maxHeight;
            final scale = viewportAspect < imageAspect
                ? constraints.maxHeight / 1774
                : constraints.maxWidth / 887;
            final imageWidth = 887 * scale;
            final imageHeight = 1774 * scale;
            return ClipRect(
              child: OverflowBox(
                minWidth: imageWidth,
                maxWidth: imageWidth,
                minHeight: imageHeight,
                maxHeight: imageHeight,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/brand/splash_screen.png',
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.fill,
                  semanticLabel: 'NUSARTA',
                ),
              ),
            );
          },
        ),
      );
}
