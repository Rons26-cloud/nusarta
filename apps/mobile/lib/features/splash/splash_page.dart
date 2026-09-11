import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/supabase_client.dart';

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
  bool _continueScheduled = false;
  bool _artworkLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(splashSystemUi);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_artworkLoading) return;
    _artworkLoading = true;
    SupabaseConfig.log('STARTUP_4_AUTH_STATE_READY');
    precacheImage(const AssetImage('assets/brand/splash_screen.png'), context)
        .then((_) => _onArtworkFrame())
        .onError((_, __) => _onArtworkFrame());
    Future<void>.delayed(const Duration(seconds: 2), _onArtworkFrame);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onArtworkFrame() {
    if (!widget.autoContinue || _continueScheduled) return;
    _continueScheduled = true;
    // Decode and paint the artwork before starting its visible display time.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) _continue();
    });
  }

  Future<void> _continue() async {
    SupabaseConfig.log('STARTUP_2_RUNAPP');
    try {
      await SupabaseConfig.initialize().timeout(const Duration(seconds: 10));
      SupabaseConfig.log('STARTUP_3_SUPABASE_READY');
    } catch (_) {
      SupabaseConfig.log(
          'initialization failed; continuing to recoverable route');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    SupabaseConfig.log('STARTUP_6_ROUTER_READY');
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: splashSystemUi,
        child: Scaffold(
          backgroundColor: splashBackground,
          body: SizedBox.expand(
            child: Image.asset(
              'assets/brand/splash_screen.png',
              // The native Android splash is icon-only; the complete approved
              // composition is rendered here as the first Flutter frame.
              // Cover preserves the artwork's aspect ratio while filling the
              // viewport, avoiding a small letterboxed image after launch.
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null || wasSynchronouslyLoaded) _onArtworkFrame();
                return child;
              },
              semanticLabel: 'NUSARTA. Keuanganmu, Dalam Kendalimu. '
                  'Dari Nusantara, untuk masa depan yang lebih baik.',
            ),
          ),
        ),
      );
}
