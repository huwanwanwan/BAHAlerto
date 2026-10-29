import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BAHAlerto – animated intro (v2)
//
//  Pure Flutter: AnimationController + Transform/Opacity + one CustomPainter.
//  No Lottie, no Rive, no extra packages.
//
//  Sequence (3.6 s at speed 1.0):
//    1. LOCATION  – the pin fades in on a soft map and pings the area.
//    2. CAR       – the car (with its water) drives in from the right and
//                   stops under the pin. Splash droplets pop on arrival.
//    3. TEXT      – the letters A-H-A-l-e-r-t-o pop up one by one
//                   (the "B" is the car's hood, so it arrives with the car).
//    4. ALERT     – the three signal arcs light up, then keep pulsing.
//    5. Tagline fades in, everything fades out → onFinished().
// ─────────────────────────────────────────────────────────────────────────────

/// The logo was cut into layers. Numbers are pixel rectangles
/// (x, y, width, height) inside the 1508 × 686 logo canvas.
class _Layer {
  const _Layer(this.asset, this.x, this.y, this.w, this.h);

  final String asset;
  final double x, y, w, h;

  /// Alignment of the point (px, py) – in canvas pixels – relative to this
  /// layer's own box. Used as the pivot for scaling.
  Alignment pivot(double px, double py) =>
      Alignment((px - x) / w * 2 - 1, (py - y) / h * 2 - 1);
}

const double _cw = 1508; // logo canvas width  (px)
const double _ch = 686; //  logo canvas height (px)

const _car = _Layer('assets/logo/car.png', 92, 233, 1250, 398);
const _pin = _Layer('assets/logo/pin.png', 264, 12, 318, 364);
const _wavesBack = _Layer('assets/logo/waves_back.png', 450, 581, 987, 93);
const _wavesFront = _Layer('assets/logo/waves_front.png', 89, 551, 1131, 109);
const _splashL = _Layer('assets/logo/splash_l.png', 12, 468, 116, 129);
const _splashR = _Layer('assets/logo/splash_r.png', 1404, 503, 92, 102);
const _arc1 = _Layer('assets/logo/arc_1.png', 1267, 335, 94, 65);
const _arc2 = _Layer('assets/logo/arc_2.png', 1265, 279, 152, 114);
const _arc3 = _Layer('assets/logo/arc_3.png', 1265, 218, 206, 161);

// The letters A H A l e r t o  (the "B" is part of the car's hood).
const _tA1 = _Layer('assets/logo/txt_A1.png', 364, 382, 215, 207);
const _tH = _Layer('assets/logo/txt_H.png', 575, 370, 179, 198);
const _tA2 = _Layer('assets/logo/txt_A2.png', 719, 366, 220, 205);
const _tL = _Layer('assets/logo/txt_l.png', 903, 337, 131, 247);
const _tE = _Layer('assets/logo/txt_e.png', 981, 397, 143, 155);
const _tR = _Layer('assets/logo/txt_r.png', 1115, 386, 90, 171);
const _tT = _Layer('assets/logo/txt_t.png', 1192, 342, 103, 173);
const _tO = _Layer('assets/logo/txt_o.png', 1293, 399, 150, 153);

const _letters = [_tA1, _tH, _tA2, _tL, _tE, _tR, _tT, _tO];

const _allLayers = [
  _car,
  _pin,
  _wavesBack,
  _wavesFront,
  _splashL,
  _splashR,
  _arc1,
  _arc2,
  _arc3,
  _tA1,
  _tH,
  _tA2,
  _tL,
  _tE,
  _tR,
  _tT,
  _tO,
];

/// Where the pin touches the ground, and the centre the 3 arcs radiate from.
const Offset _pinTip = Offset(425, 373);
const Offset _arcOrigin = Offset(1284, 418);

/// Leftmost pixel of the parts that drive in (car body + water).
const double _drivingLeft = 89;

/// How far below the logo's centre the road runs (so the car sits on it).
const double _roadDropFactor = 0.30; // × logo height

const Color _taglineGrey = Color(0xFF6B7280);

class BahalertoSplash extends StatefulWidget {
  const BahalertoSplash({
    super.key,
    this.onFinished,
    this.speed = 1.0,
    this.tagline = 'Alamin ang baha sa inyong lugar —\nbago ka pa umalis.',
  });

  /// Called once, when the intro has finished (go to your next screen).
  final VoidCallback? onFinished;

  /// 1.0 = 3.6 s. Use 1.5 for a quicker intro (2.4 s), 0.8 for a slower one.
  final double speed;

  /// Tagalog tagline under the logo. Pass `null` to hide it.
  final String? tagline;

  @override
  State<BahalertoSplash> createState() => _BahalertoSplashState();
}

class _BahalertoSplashState extends State<BahalertoSplash>
    with SingleTickerProviderStateMixin {
  static const double _seconds = 3.6; // total length at speed 1.0
  static const double _holdAt = 3.0; //  frame shown when animations are off

  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c =
        AnimationController(
          vsync: this,
          duration: Duration(
            milliseconds: (_seconds * 1000 / widget.speed).round(),
          ),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onFinished?.call();
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  Future<void> _start() async {
    // Load every image first so nothing pops in half-way through.
    try {
      await Future.wait(
        _allLayers.map((l) => precacheImage(AssetImage(l.asset), context)),
      );
    } catch (_) {
      // If an asset is missing, still run the animation.
    }
    if (!mounted) return;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      // Respect the system "reduce motion" setting: show the finished logo.
      _c.value = _holdAt / _seconds;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) widget.onFinished?.call();
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ── timeline helper ────────────────────────────────────────────────────────

  /// 0 → 1 between second [a] and second [b], shaped by [curve].
  static double _seg(
    double s,
    double a,
    double b, [
    Curve curve = Curves.linear,
  ]) {
    final t = ((s - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curve.transform(t);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;

          final logoW = math.min(w * 0.9, 480.0);
          final k = logoW / _cw; // canvas px → logical px
          final logoH = _ch * k;
          final left = (w - logoW) / 2;
          final top = (h - logoH) / 2 - 28;

          final tip = Offset(left + _pinTip.dx * k, top + _pinTip.dy * k);
          final center = Offset(w / 2, top + logoH / 2);
          final roadAt = center + Offset(0, logoH * _roadDropFactor);

          // How far right the car must start so it is fully off-screen.
          final travel = w - left - _drivingLeft * k + 16;

          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final s = _c.value * _seconds;
              final exit = _seg(s, 3.2, 3.6);

              // Map camera follows the car: fast while it drives, then eases.
              final dist =
                  _MapPainter.totalDist * _seg(s, 0, 3.4, Curves.easeOutCubic);
              final turn = Curves.easeInOut.transform(
                ((dist - 230) / 130).clamp(0.0, 1.0).toDouble(),
              );

              final painter = _MapPainter(
                opacity: _seg(s, 0, 0.5, Curves.easeOut),
                center: center,
                roadAt: roadAt,
                cam: _MapPainter.camAt(dist),
                angle: -_MapPainter.turnAngle * turn,
                zoom: 1 + 0.10 * _seg(s, 0, 3.4),
                flood: _seg(s, 1.0, 1.9, Curves.easeOutCubic),
                tip: tip,
                ping: s - 0.35, // pin pings its location as soon as it appears
              );

              return Opacity(
                opacity: 1 - exit,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: painter)),
                    Positioned(
                      left: left,
                      top: top,
                      width: logoW,
                      height: logoH,
                      child: _buildLogo(s, k, logoW, logoH, travel),
                    ),
                    if (widget.tagline != null)
                      Positioned(
                        left: 24,
                        right: 24,
                        top: top + logoH + 26,
                        child: _buildTagline(s, widget.tagline!),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogo(double s, double k, double w, double h, double travel) {
    // 1 ─ LOCATION: the pin fades in and grows slightly.
    final pinFade = _seg(s, 0.10, 0.45);
    final pinScale = 0.55 + 0.45 * _seg(s, 0.10, 0.65, Curves.easeOutBack);

    // 2 ─ CAR: drives in from the right, water travels with it.
    final drive = _seg(s, 0.60, 1.40, Curves.easeOutCubic);
    final driveOffset = Offset(travel * (1 - drive), 0);

    // After it stops, the two water bands drift gently in opposite directions.
    final flow = _seg(s, 1.3, 1.9);
    final frontOffset =
        driveOffset +
        Offset(
          math.sin(s * 1.5) * 0.007 * w * flow,
          math.sin(s * 2.3) * 0.006 * h * flow,
        );
    final backOffset =
        driveOffset +
        Offset(
          -math.sin(s * 1.5 + 0.6) * 0.009 * w * flow,
          math.sin(s * 2.3 + 1.8) * 0.006 * h * flow,
        );

    // Splash droplets pop as the car arrives.
    final popL = _seg(s, 1.25, 1.75, Curves.elasticOut);
    final popR = _seg(s, 1.30, 1.80, Curves.elasticOut);

    // 3 ─ TEXT: letters pop up one by one from the water line.
    final letterWidgets = <Widget>[];
    for (var i = 0; i < _letters.length; i++) {
      final start = 1.35 + i * 0.07;
      letterWidgets.add(
        _piece(
          _letters[i],
          k,
          opacity: _seg(s, start, start + 0.15),
          scale: _seg(s, start, start + 0.38, Curves.easeOutBack),
          align: Alignment.bottomCenter,
        ),
      );
    }

    // 4 ─ ALERT: arcs appear one by one, then pulse like a signal.
    final idle = _seg(s, 2.65, 3.0);
    Widget arc(_Layer l, double start, int index) {
      final t = _seg(s, start, start + 0.45, Curves.easeOutBack);
      final fade = _seg(s, start, start + 0.18);
      final pulse =
          0.5 + 0.5 * math.sin(2 * math.pi * (s - 2.7) * 0.9 - index * 1.1);
      return _piece(
        l,
        k,
        opacity: fade * (1 - idle * 0.45 * (1 - pulse)),
        scale: 0.5 + 0.5 * t,
        align: l.pivot(_arcOrigin.dx, _arcOrigin.dy),
      );
    }

    return Stack(
      clipBehavior: Clip.none, // the car starts outside the logo box
      children: [
        ...letterWidgets, // under the car, so the rear wheel overlaps the "o"
        _piece(_car, k, offset: driveOffset),
        _piece(
          _pin,
          k,
          opacity: pinFade,
          scale: pinScale,
          align: Alignment.bottomCenter,
        ),
        _piece(_wavesBack, k, offset: backOffset),
        _piece(_wavesFront, k, offset: frontOffset),
        _piece(_splashL, k, scale: popL, align: Alignment.bottomRight),
        _piece(_splashR, k, scale: popR, align: Alignment.bottomLeft),
        arc(_arc1, 1.95, 0),
        arc(_arc2, 2.08, 1),
        arc(_arc3, 2.21, 2),
      ],
    );
  }

  Widget _buildTagline(double s, String text) {
    final t = _seg(s, 2.4, 2.95, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.5,
            letterSpacing: 0.1,
            color: _taglineGrey,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  /// One logo layer, placed by its pixel rectangle and animated with
  /// opacity / offset / scale.
  Widget _piece(
    _Layer l,
    double k, {
    double opacity = 1,
    Offset offset = Offset.zero,
    double scale = 1,
    Alignment align = Alignment.center,
  }) {
    if (opacity <= 0.001 || scale <= 0.001) return const SizedBox.shrink();

    Widget child = Image.asset(
      l.asset,
      width: l.w * k,
      height: l.h * k,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );
    if (opacity < 1) {
      child = Opacity(
        opacity: opacity.clamp(0.0, 1.0).toDouble(),
        child: child,
      );
    }
    if (scale != 1) {
      child = Transform.scale(scale: scale, alignment: align, child: child);
    }
    if (offset != Offset.zero) {
      child = Transform.translate(offset: offset, child: child);
    }

    return Positioned(
      left: l.x * k,
      top: l.y * k,
      width: l.w * k,
      height: l.h * k,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Soft map background + radar rings
//
//  The road runs right-to-left (the car faces left). The "camera" slides along
//  it, turns a corner, and keeps going – like the navigation map in the video.
// ─────────────────────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.opacity,
    required this.center,
    required this.roadAt,
    required this.cam,
    required this.angle,
    required this.zoom,
    required this.flood,
    required this.tip,
    required this.ping,
  });

  final double opacity; // whole map fade-in
  final Offset center; //  middle of the logo (centre of the soft edge fade)
  final Offset roadAt; //  screen point the road passes through
  final Offset cam; //     camera position in map space
  final double angle; //   camera rotation (radians)
  final double zoom;
  final double flood; //   0 → 1: flood patch on the road ahead
  final Offset tip; //     screen position of the pin's tip
  final double ping; //    seconds since the first ping (negative = not yet)

  // Road geometry (map space): straight to the left, then bends up-left.
  static const double turnAngle = 0.60; //                  radians
  static const Offset _start = Offset(260, 0);
  static const Offset _corner = Offset(-60, 0);
  static const Offset _dir2 = Offset(-0.8253, -0.5646); //  cos/sin of 0.60
  static const double l1 = 320; //   start → corner
  static const double l2 = 150; //   corner → end
  static const double totalDist = l1 + l2;
  static const Offset _floodSpot = Offset(-183.8, -84.7); // corner + dir2 * 150

  /// Radar ring colours, in the order the rings are sent out
  /// (sampled from the logo: green · orange · red).
  static const List<Color> _radarColors = [
    Color(0xFF1FA050), // green
    Color(0xFFF96A0C), // orange
    Color(0xFFED2D22), // red
  ];

  /// Camera position after travelling [dist] along the road.
  static Offset camAt(double dist) {
    if (dist <= l1) return Offset(_start.dx - dist, 0);
    final u = dist - l1;
    return Offset(_corner.dx + _dir2.dx * u, _dir2.dy * u);
  }

  static final Path _road = Path()
    ..moveTo(1100, 0)
    ..lineTo(_corner.dx, _corner.dy)
    ..lineTo(_corner.dx + _dir2.dx * 1000, _corner.dy + _dir2.dy * 1000);

  static final Path _streets = _buildStreets();

  static final Paint _roadPaint = Paint()
    ..color = const Color(0x1F6B7280)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 34
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  static final Paint _streetPaint = Paint()
    ..color = const Color(0x249CA3AF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  static final Paint _floodPaint = Paint()
    ..color = const Color(0x330AA0F0)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

  /// Deterministic pseudo-random number in [0, 1) – same result every frame.
  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static Path _buildStreets() {
    final p = Path();
    for (var i = -9; i <= 9; i++) {
      // vertical streets
      final x = i * 56.0 + (_hash(i, 1) - 0.5) * 20;
      var y = -760.0;
      var j = 0;
      while (y < 760) {
        final len = 70 + _hash(i, j + 10) * 210;
        if (_hash(i, j + 50) > 0.3) {
          p.moveTo(x, y);
          p.lineTo(x, y + len);
        }
        y += len + 16 + _hash(i, j + 90) * 34;
        j++;
      }
      // horizontal streets
      final yy = i * 56.0 + (_hash(i, 2) - 0.5) * 20;
      var xx = -760.0;
      var jj = 0;
      while (xx < 760) {
        final len = 70 + _hash(i + 100, jj + 10) * 210;
        if (_hash(i + 100, jj + 50) > 0.3) {
          p.moveTo(xx, yy);
          p.lineTo(xx + len, yy);
        }
        xx += len + 16 + _hash(i + 100, jj + 90) * 34;
        jj++;
      }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (opacity > 0.001) {
      // Draw the map into its own layer so we can fade its edges to white.
      canvas.saveLayer(
        rect,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );

      canvas.save();
      canvas.translate(roadAt.dx, roadAt.dy);
      canvas.rotate(angle);
      canvas.scale(zoom);
      canvas.translate(-cam.dx, -cam.dy);
      canvas.drawPath(_streets, _streetPaint);
      canvas.drawPath(_road, _roadPaint);
      if (flood > 0.001) {
        canvas.drawCircle(_floodSpot, 64 * flood, _floodPaint);
      }
      canvas.restore();

      // Feather: opaque in the middle, transparent towards the edges.
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader =
              const RadialGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.34, 1.0],
              ).createShader(
                Rect.fromCircle(center: center, radius: size.width * 0.80),
              ),
      );
      canvas.restore();
    }

    // Radar: rings spread from the pin, one colour per ring –
    // green (safe) → orange (warning) → red (danger).
    if (ping >= 0) {
      for (var i = 0; i < _radarColors.length; i++) {
        final local = ping - i * 0.45;
        if (local < 0) continue;
        final p = (local / 1.6) % 1.0;
        final radius = 6 + Curves.easeOutCubic.transform(p) * size.width * 0.5;
        final fade = math.pow(1 - p, 1.5).toDouble();
        final color = _radarColors[i];

        // soft tinted disc (remove these 5 lines if you only want the rings)
        canvas.drawCircle(
          tip,
          radius,
          Paint()
            ..style = PaintingStyle.fill
            ..color = color.withAlpha((fade * 0.08 * 255).round()),
        );
        // the ring itself
        canvas.drawCircle(
          tip,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2 - 2 * p
            ..color = color.withAlpha((fade * 0.55 * 255).round()),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true; // repaints every frame
}
