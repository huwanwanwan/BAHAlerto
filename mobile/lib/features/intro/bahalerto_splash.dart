import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BAHAlerto – animated intro (v2)
//
//  Pure Flutter: AnimationController + Transform/Opacity + one CustomPainter.
//  No Lottie, no Rive, no extra packages.
//
//  Sequence (3.6 s at speed 1.0):
//    1. LOCATION  – the pin fades in on a soft city map. A green route draws
//                   towards it and green / orange / red radar rings ping out.
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
  _car, _pin, _wavesBack, _wavesFront, _splashL, _splashR,
  _arc1, _arc2, _arc3,
  _tA1, _tH, _tA2, _tL, _tE, _tR, _tT, _tO,
];

/// Where the pin touches the ground, and the centre the 3 arcs radiate from.
const Offset _pinTip = Offset(425, 373);
const Offset _arcOrigin = Offset(1284, 418);

/// Leftmost pixel of the parts that drive in (car body + water).
const double _drivingLeft = 89;

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
    _c = AnimationController(
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

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
  static double _seg(double s, double a, double b, [Curve curve = Curves.linear]) {
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

          // Shrink the map a little on short screens so the whole route fits.
          final fit = math.min(1.0, (tip.dy - 44) / 340).clamp(0.55, 1.0).toDouble();

          // How far right the car must start so it is fully off-screen.
          final travel = w - left - _drivingLeft * k + 16;

          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final s = _c.value * _seconds;
              final exit = _seg(s, 3.2, 3.6);

              // Map camera: settles onto the pin (rotate + zoom around it).
              final settle = _seg(s, 0, 2.2, Curves.easeOutCubic);

              final painter = _MapPainter(
                opacity: _seg(s, 0, 0.5, Curves.easeOut),
                tip: tip,
                angle: 0.35 * (1 - settle),
                zoom: fit * (0.90 + 0.10 * settle + 0.04 * _seg(s, 2.2, 3.6)),
                flood: _seg(s, 1.0, 2.0, Curves.easeOutCubic),
                route: _seg(s, 0.30, 1.15, Curves.easeInOutCubic),
                origin: _seg(s, 0.25, 0.55),
                flow: s,
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
    final frontOffset = driveOffset +
        Offset(
          math.sin(s * 1.5) * 0.007 * w * flow,
          math.sin(s * 2.3) * 0.006 * h * flow,
        );
    final backOffset = driveOffset +
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
        _piece(_pin, k,
            opacity: pinFade, scale: pinScale, align: Alignment.bottomCenter),
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
      child = Opacity(opacity: opacity.clamp(0.0, 1.0).toDouble(), child: child);
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
//  Map background: city blocks, parks, a river, a route to the pin, and the
//  green / orange / red radar rings.
//
//  Everything is drawn in "map space" where the DESTINATION (the pin's tip) is
//  the point (0, 0). The camera only rotates / zooms around that point, so the
//  route always ends exactly under the pin.
// ─────────────────────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.opacity,
    required this.tip,
    required this.angle,
    required this.zoom,
    required this.flood,
    required this.route,
    required this.origin,
    required this.flow,
    required this.ping,
  });

  final double opacity; // whole map fade-in
  final Offset tip; //     screen position of the pin's tip = the destination
  final double angle; //   map rotation around the destination (radians)
  final double zoom; //    map scale
  final double flood; //   0 → 1: the river swells
  final double route; //   0 → 1: how much of the route is drawn
  final double origin; //  0 → 1: fade-in of the start dot
  final double flow; //    seconds – moves the dashes along the route
  final double ping; //    seconds since the first radar ping (<0 = not yet)

  // ── map geometry ──────────────────────────────────────────────────────────

  static const double _grid = 56; // distance between streets

  // Streets used by the route stay free of "merged" blocks.
  static const Set<int> _routeCols = {0, 3};
  static const Set<int> _routeRows = {-3, 0};

  /// Route (map space, y down): start → corner → corner → destination.
  static const List<Offset> _routePts = [
    Offset(168, -336),
    Offset(168, -168),
    Offset(0, -168),
    Offset(0, 0),
  ];

  /// Radar ring colours, in the order the rings are sent out
  /// (sampled from the logo: green · orange · red).
  static const List<Color> _radarColors = [
    Color(0xFF1FA050), // green
    Color(0xFFF96A0C), // orange
    Color(0xFFED2D22), // red
  ];

  static const Color _routeGreen = Color(0xFF1FA050);

  /// Deterministic pseudo-random number in [0, 1) – same result every frame.
  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// 0 = empty plot, 1 = park, 2 = building block.
  static int _kind(int i, int j) {
    final h = _hash(i, j);
    if (h < 0.06) return 0;
    if (h < 0.16) return 1;
    return 2;
  }

  static Rect _cell(int i, int j) {
    final ins = 5.0 + _hash(i + 40, j + 40) * 2.5;
    return Rect.fromLTRB(
      i * _grid + ins,
      j * _grid + ins,
      (i + 1) * _grid - ins,
      (j + 1) * _grid - ins,
    );
  }

  /// Returns [blocks, parks] as two ready-made paths.
  static List<Path> _buildGeometry() {
    final blocks = Path();
    final parks = Path();
    const radius = Radius.circular(3);
    for (var i = -10; i < 10; i++) {
      for (var j = -10; j < 10; j++) {
        final kind = _kind(i, j);
        if (kind == 0) continue;
        final r = _cell(i, j);
        if (kind == 1) {
          parks.addRRect(RRect.fromRectAndRadius(r, radius));
          continue;
        }
        blocks.addRRect(RRect.fromRectAndRadius(r, radius));

        // Sometimes join two neighbouring blocks into one big block
        // (never across the streets the route runs on).
        if (_kind(i + 1, j) == 2 &&
            !_routeCols.contains(i + 1) &&
            _hash(i + 80, j + 80) < 0.22) {
          final b = _cell(i + 1, j);
          blocks.addRect(Rect.fromLTRB(
              r.right, math.max(r.top, b.top), b.left, math.min(r.bottom, b.bottom)));
        }
        if (_kind(i, j + 1) == 2 &&
            !_routeRows.contains(j + 1) &&
            _hash(i + 120, j + 120) < 0.22) {
          final b = _cell(i, j + 1);
          blocks.addRect(Rect.fromLTRB(
              math.max(r.left, b.left), r.bottom, math.min(r.right, b.right), b.top));
        }
      }
    }
    return [blocks, parks];
  }

  static final List<Path> _geo = _buildGeometry();

  /// A river that winds below the logo – it "floods" when [flood] grows.
  static final Path _river = Path()
    ..moveTo(-620, 330)
    ..cubicTo(-260, 120, 60, 360, 620, 170);

  /// Polyline with rounded corners.
  static Path _roundedPolyline(List<Offset> pts, double r) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final next = pts[i + 1];
      final a = cur + (prev - cur) / (prev - cur).distance * r;
      final b = cur + (next - cur) / (next - cur).distance * r;
      p.lineTo(a.dx, a.dy);
      p.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
    return p;
  }

  static final Path _routePath = _roundedPolyline(_routePts, 16);
  static final _routeMetric = _routePath.computeMetrics().first;
  static final double _routeLen = _routeMetric.length;

  // ── paints (created once) ─────────────────────────────────────────────────

  static final Paint _blockPaint = Paint()..color = const Color(0x126B7280);
  static final Paint _parkPaint = Paint()..color = const Color(0x1C22A559);

  static final Paint _riverPaint = Paint()
    ..color = const Color(0x240AA0F0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 34
    ..strokeCap = StrokeCap.round;

  static final Paint _casingPaint = Paint()
    ..color = const Color(0xD9FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _routeBasePaint = Paint()
    ..color = const Color(0x401FA050)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _dashPaint = Paint()
    ..color = _routeGreen
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ── painting ──────────────────────────────────────────────────────────────

  void _applyCamera(Canvas canvas) {
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.scale(zoom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1 ─ blocks, parks and river, in their own layer so the top and bottom
    //     can fade out to white.
    if (opacity > 0.001) {
      canvas.saveLayer(
        rect,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );

      canvas.save();
      _applyCamera(canvas);
      canvas.drawPath(_geo[0], _blockPaint);
      canvas.drawPath(_geo[1], _parkPaint);
      canvas.drawPath(_river, _riverPaint);
      if (flood > 0.001) {
        // the river swells and spills over
        canvas.drawPath(
          _river,
          Paint()
            ..color = const Color(0x330AA0F0)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 30 + 60 * flood
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      canvas.restore();

      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0.0, 0.16, 0.62, 0.88],
          ).createShader(rect),
      );
      canvas.restore();
    }

    // 2 ─ the route: draws from the start dot to the pin, dashes keep flowing.
    if (route > 0.001) {
      canvas.save();
      _applyCamera(canvas);

      final drawn = _routeLen * route;
      final line = _routeMetric.extractPath(0, drawn);
      canvas.drawPath(line, _casingPaint);
      canvas.drawPath(line, _routeBasePaint);

      const dash = 10.0;
      const period = 18.0; // dash + gap
      final phase = (flow * 40) % period;
      for (var d = phase - period; d < drawn; d += period) {
        final a = math.max(d, 0.0);
        final b = math.min(d + dash, drawn);
        if (b > a) canvas.drawPath(_routeMetric.extractPath(a, b), _dashPaint);
      }

      // start dot
      if (origin > 0.001) {
        final o = _routePts.first;
        canvas.drawCircle(
          o,
          7,
          Paint()..color = Color.fromRGBO(255, 255, 255, origin),
        );
        canvas.drawCircle(
          o,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = _routeGreen.withAlpha((origin * 255).round()),
        );
      }

      // glowing dot at the tip of the line while it is travelling
      final head = _routeMetric.getTangentForOffset(drawn)?.position;
      if (head != null && route < 0.995) {
        canvas.drawCircle(
          head,
          11,
          Paint()
            ..color = const Color(0x401FA050)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(head, 5.5, Paint()..color = _routeGreen);
        canvas.drawCircle(
          head,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }
      canvas.restore();
    }

    // 3 ─ radar: rings spread from the pin, one colour per ring –
    //     green (safe) → orange (warning) → red (danger).
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
