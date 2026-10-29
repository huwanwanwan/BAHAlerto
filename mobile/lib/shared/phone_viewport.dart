import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The desktop web phone preview has no OS chrome. Native/mobile browsers keep
/// their actual status bar; all routes share the same protected top inset.
class PhoneViewport extends StatelessWidget {
  final Widget child;
  final bool? showPreviewStatus;
  const PhoneViewport({super.key, required this.child, this.showPreviewStatus});
  @override
  Widget build(BuildContext context) {
    final desktop = ![
      TargetPlatform.android,
      TargetPlatform.iOS,
    ].contains(defaultTargetPlatform);
    final preview =
        showPreviewStatus ??
        (kIsWeb && desktop && MediaQuery.sizeOf(context).width <= 640);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (preview)
                const DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    color: Color(0xFF14261D),
                    decoration: TextDecoration.none,
                  ),
                  child: _PreviewStatusBar(),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStatusBar extends StatefulWidget {
  const _PreviewStatusBar();
  @override
  State<_PreviewStatusBar> createState() => _PreviewStatusBarState();
}

class _PreviewStatusBarState extends State<_PreviewStatusBar> {
  late final Timer clock;
  DateTime now = DateTime.now();
  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label:
          'Phone preview. Current time $time. Signal, Wi-Fi and 100 percent battery are illustrative.',
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey('phone-preview-status'),
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Row(
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14261D),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.signal_cellular_alt_rounded,
                size: 15,
                color: Color(0xFF14261D),
              ),
              const SizedBox(width: 4),
              const Text(
                '4G',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.wifi_rounded,
                size: 15,
                color: Color(0xFF14261D),
              ),
              const SizedBox(width: 7),
              const Text(
                '100%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.battery_full_rounded,
                size: 17,
                color: Color(0xFF14261D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
