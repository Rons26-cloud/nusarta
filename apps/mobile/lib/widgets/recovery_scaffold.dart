import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class RecoveryScaffold extends StatelessWidget {
  const RecoveryScaffold(
      {super.key,
      required this.asset,
      required this.child,
      required this.onBack});
  final String asset;
  final Widget child;
  final VoidCallback onBack;

  Widget _slice(Alignment alignment, double fraction) => ExcludeSemantics(
      child: ClipRect(
          child: Align(
              alignment: alignment,
              heightFactor: fraction,
              child: Image.asset(asset,
                  width: double.infinity, fit: BoxFit.fitWidth))));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.deepEmerald,
        body: SafeArea(
            child: ColoredBox(
          color: AppColors.isDark ? AppColors.surfaceElevated : AppColors.cream,
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(children: [
                                Stack(children: [
                                  _slice(Alignment.topCenter, .25),
                                  Positioned(
                                      left: 8,
                                      top: 18,
                                      child: IconButton.filled(
                                          style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.deepEmerald),
                                          tooltip: 'Kembali',
                                          onPressed: onBack,
                                          icon: const Icon(Icons.arrow_back,
                                              color: Colors.white))),
                                ]),
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 16, 24, 24),
                                    child: Center(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 440),
                                            child: child))),
                              ]),
                              _slice(Alignment.bottomCenter, .19),
                            ])),
                  )),
        )),
      );
}
