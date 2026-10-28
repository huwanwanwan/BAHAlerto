import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets.dart';

/// Remove this wrapper from MaterialApp.home to disable the splash.
class IntroScreen extends StatefulWidget {
  final Widget child;
  const IntroScreen({super.key, required this.child});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController timeline =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4800),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => finished = true);
        }
      });
  final geometry = _Geometry();
  ui.Image? logo;
  bool started = false;
  bool finished = false;
  @override
  void initState() {
    super.initState();
    loadLogo();
  }

  Future<void> loadLogo() async {
    final bytes = await rootBundle.load('assets/bahalerto-logo.png');
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: 752,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => logo = frame.image);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => finished = true);
      });
    } else {
      timeline.forward();
    }
  }

  void finish() {
    timeline.stop();
    setState(() => finished = true);
  }

  @override
  void dispose() {
    timeline.dispose();
    logo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return widget.child;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: finish,
                  child: const Text('Skip intro'),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AspectRatio(
                      aspectRatio: 360 / 390,
                      child: Semantics(
                        image: true,
                        label:
                            'A green car transforms into BAHAlerto, followed by the flood awareness logo',
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _SplashPainter(timeline, geometry, logo),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'DEMO • Sample data only',
                style: TextStyle(color: mutedText, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot {
  final Offset from, to;
  final Color fromColor, toColor;
  const _Dot(this.from, this.to, this.fromColor, this.toColor);
}

/// Filled vector letters provide real target silhouettes, including counters.
class _Geometry {
  final List<(Path, Color)> letters = [];
  final List<_Dot> dots = [];
  final body = Path()
    ..moveTo(115, 229)
    ..lineTo(127, 204)
    ..quadraticBezierTo(131, 197, 140, 197)
    ..lineTo(185, 197)
    ..quadraticBezierTo(194, 197, 204, 217)
    ..lineTo(232, 224)
    ..quadraticBezierTo(241, 226, 241, 237)
    ..lineTo(241, 249)
    ..lineTo(112, 249)
    ..lineTo(112, 237)
    ..quadraticBezierTo(112, 231, 115, 229)
    ..close();
  final windows = Path()
    ..moveTo(134, 205)
    ..lineTo(155, 205)
    ..lineTo(155, 222)
    ..lineTo(126, 222)
    ..close()
    ..moveTo(161, 205)
    ..lineTo(184, 205)
    ..lineTo(195, 222)
    ..lineTo(161, 222)
    ..close();
  final wheels = Path()
    ..addOval(const Rect.fromLTWH(127, 237, 25, 25))
    ..addOval(const Rect.fromLTWH(204, 237, 25, 25));
  _Geometry() {
    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    void letter(Path p, double x, Color color) =>
        letters.add((p.shift(Offset(x, 258)), color));
    Path rect(double x, double y, double w, double h) =>
        Path()..addRect(Rect.fromLTWH(x, y, w, h));
    final b = Path()..fillType = PathFillType.evenOdd;
    b.addPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(17, 0)
        ..cubicTo(36, 0, 36, 21, 25, 24)
        ..cubicTo(40, 28, 36, 50, 17, 50)
        ..lineTo(0, 50)
        ..close(),
      Offset.zero,
    );
    b.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 8, 14, 12),
        const Radius.circular(5),
      ),
    );
    b.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 29, 16, 13),
        const Radius.circular(5),
      ),
    );
    letter(b, 25, ink);
    Path a() => Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(
        polygon([
          const Offset(0, 50),
          const Offset(15, 0),
          const Offset(26, 0),
          const Offset(41, 50),
          const Offset(31, 50),
          const Offset(27, 37),
          const Offset(13, 37),
          const Offset(9, 50),
        ]),
        Offset.zero,
      )
      ..addPolygon([
        const Offset(16, 29),
        const Offset(21, 12),
        const Offset(25, 29),
      ], true);
    letter(a(), 63, ink);
    letter(
      Path()
        ..addPath(rect(0, 0, 9, 50), Offset.zero)
        ..addPath(rect(27, 0, 9, 50), Offset.zero)
        ..addPath(rect(8, 20, 20, 9), Offset.zero),
      109,
      ink,
    );
    letter(a(), 153, primaryGreen);
    letter(rect(0, 0, 9, 50), 201, primaryGreen);
    // Union fills the crossbar without cancelling overlapping contours.
    final eShape = Path.combine(
      PathOperation.union,
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(const Rect.fromLTWH(0, 14, 34, 37))
        ..addOval(const Rect.fromLTWH(8, 22, 18, 21)),
      rect(7, 29, 27, 7),
    );
    letter(
      Path.combine(PathOperation.difference, eShape, rect(23, 36, 13, 7)),
      217,
      lightGreen,
    );
    letter(
      Path()
        ..addRect(const Rect.fromLTWH(0, 15, 8, 35))
        ..moveTo(7, 25)
        ..quadraticBezierTo(14, 12, 25, 16)
        ..lineTo(25, 25)
        ..quadraticBezierTo(15, 21, 7, 33)
        ..close(),
      258,
      warningOrange,
    );
    letter(
      Path()
        ..addRect(const Rect.fromLTWH(9, 4, 8, 37))
        ..addRect(const Rect.fromLTWH(0, 16, 27, 8))
        ..moveTo(9, 37)
        ..lineTo(17, 37)
        ..quadraticBezierTo(16, 44, 26, 42)
        ..lineTo(26, 50)
        ..quadraticBezierTo(7, 54, 9, 37)
        ..close(),
      289,
      warningOrange,
    );
    letter(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(const Rect.fromLTWH(0, 14, 32, 37))
        ..addOval(const Rect.fromLTWH(8, 22, 16, 21)),
      322,
      dangerRed,
    );
    final source = <(Offset, Color)>[];
    for (double y = 197; y < 263; y += 2) {
      for (double x = 112; x < 242; x += 2) {
        final p = Offset(x, y);
        if (wheels.contains(p)) {
          source.add((p, const Color(0xFF263C30)));
        } else if (windows.contains(p)) {
          source.add((p, const Color(0xFFC3E3D0)));
        } else if (body.contains(p)) {
          source.add((p, primaryGreen));
        }
      }
    }
    source.shuffle(math.Random(24));
    var i = 0;
    for (final (path, color) in letters) {
      for (double y = 258; y < 310; y += 2) {
        for (double x = 25; x < 355; x += 2) {
          final p = Offset(x, y);
          if (path.contains(p)) {
            final s = source[i++ % source.length];
            dots.add(_Dot(s.$1, p, s.$2, color));
          }
        }
      }
    }
  }
}

class _SplashPainter extends CustomPainter {
  final Animation<double> timeline;
  final _Geometry geometry;
  final ui.Image? logo;
  _SplashPainter(this.timeline, this.geometry, this.logo)
    : super(repaint: timeline);
  double phase(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 390);
    final t = timeline.value;
    final arrival = Curves.easeOutCubic.transform(phase(t, .03, .27));
    final morph = Curves.easeInOutCubic.transform(phase(t, .34, .67));
    final carX = -280 * (1 - arrival);
    final paint = Paint()..isAntiAlias = true;
    if (morph == 0) {
      canvas.save();
      canvas.translate(carX, 0);
      canvas.drawPath(geometry.body, paint..color = primaryGreen);
      canvas.drawPath(geometry.windows, paint..color = const Color(0xFFC3E3D0));
      canvas.drawPath(geometry.wheels, paint..color = const Color(0xFF263C30));
      for (final x in [139.5, 216.5]) {
        canvas.drawCircle(
          Offset(x, 249.5),
          5,
          paint..color = const Color(0xFFD9E5DE),
        );
      }
      canvas.restore();
    } else if (morph < 1) {
      // Every tile begins inside a body, window or wheel and lands inside a glyph.
      // No text overlay or crossfade is used during the transformation.
      for (var i = 0; i < geometry.dots.length; i++) {
        final dot = geometry.dots[i];
        final arc = math.sin(morph * math.pi);
        final p =
            Offset.lerp(dot.from, dot.to, morph)! +
            Offset(math.sin(i * 2.3) * arc * 8, -arc * (12 + (i % 7) * 2));
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 2.15, height: 2.15),
          paint..color = Color.lerp(dot.fromColor, dot.toColor, morph)!,
        );
      }
    } else {
      for (final (path, color) in geometry.letters) {
        canvas.drawPath(path, paint..color = color);
      }
    }
    final enter = Curves.easeOutCubic.transform(phase(t, .69, .82));
    if (enter > 0 && logo != null) {
      canvas.save();
      canvas.translate(180, 140);
      canvas.scale(.65 + .35 * enter);
      canvas.translate(-180, -140);
      // Draw the original emblem directly from the official asset, excluding its wordmark.
      final image = logo!;
      final src = Rect.fromLTRB(
        image.width * .27,
        image.height * .20,
        image.width * .73,
        image.height * .615,
      );
      canvas.drawImageRect(
        image,
        src,
        const Rect.fromLTWH(78, 40, 204, 184),
        Paint()
          ..color = Colors.white.withValues(alpha: enter)
          ..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
    final wave = phase(t, .81, .89);
    if (wave > 0) {
      final path = Path();
      for (double x = 110; x <= 250; x += 3) {
        final y = 234 + math.sin((x - 110) / 20 - t * 16) * 2.3;
        if (x == 110) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = primaryGreen.withValues(alpha: wave * .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    // A single restrained pulse follows the wave; no repeated flashing.
    final pulse = math.sin(phase(t, .87, .99) * math.pi) * .24;
    if (pulse > 0) {
      for (final side in [-1.0, 1.0]) {
        for (var ring = 0; ring < 2; ring++) {
          final x = 180 + side * (77 + ring * 14);
          canvas.drawPath(
            Path()
              ..moveTo(x, 62)
              ..quadraticBezierTo(x + side * 19, 104, x, 146),
            Paint()
              ..color = (ring == 0 ? warningOrange : dangerRed).withValues(
                alpha: pulse,
              )
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.logo != logo || old.timeline != timeline;
}
