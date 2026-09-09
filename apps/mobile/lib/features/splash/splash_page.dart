import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Color(0xff063b2f),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Image.asset(
              'assets/brand/splash_screen.png',
              fit: BoxFit.contain,
              semanticLabel: 'NUSARTA',
            ),
          ),
        ),
      );
}
