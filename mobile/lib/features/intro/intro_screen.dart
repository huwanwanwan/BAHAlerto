import 'package:flutter/material.dart';
import 'bahalerto_splash.dart';

/// Keeps app entry routing separate from the supplied layered logo animation.
class IntroScreen extends StatefulWidget {
  final Widget child;
  const IntroScreen({super.key, required this.child});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool finished = false;
  void finish() {
    if (mounted && !finished) setState(() => finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.035, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: finished || reduceMotion
          ? KeyedSubtree(
              key: const ValueKey('intro-destination'),
              child: widget.child,
            )
          : Stack(
              key: const ValueKey('intro-animation'),
              fit: StackFit.expand,
              children: [
                Semantics(
                  image: true,
                  label:
                      'BAHAlerto: location pin, arriving car, letters and alert signal',
                  child: RepaintBoundary(
                    child: BahalertoSplash(onFinished: finish),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  right: 16,
                  child: TextButton(
                    onPressed: finish,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF005C38),
                    ),
                    child: const Text('Skip intro'),
                  ),
                ),
              ],
            ),
    );
  }
}
