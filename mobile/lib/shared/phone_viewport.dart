import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The desktop web phone preview has no OS chrome. Native/mobile browsers keep
/// their actual status bar; all routes share the same protected top inset.
const loginHeaderGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF004D35), Color(0xFF238C45), Color(0xFFA4CD49)],
  stops: [0, .56, 1],
);

class _PhoneStatusController extends ChangeNotifier {
  final owners = <Object>{};
  bool disposed = false;
  bool get branded => owners.isNotEmpty;
  void update(Object owner, bool attach) {
    final changed = attach ? owners.add(owner) : owners.remove(owner);
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _PhoneStatusBinding extends InheritedWidget {
  final _PhoneStatusController controller;
  const _PhoneStatusBinding({required this.controller, required super.child});
  static _PhoneStatusController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PhoneStatusBinding>()
      ?.controller;
  @override
  bool updateShouldNotify(_PhoneStatusBinding oldWidget) =>
      controller != oldWidget.controller;
}

/// Registers a branded header while retaining the shared safe system inset.
class HeaderStatusScope extends StatefulWidget {
  final Widget child;
  const HeaderStatusScope({super.key, required this.child});
  @override
  State<HeaderStatusScope> createState() => _HeaderStatusScopeState();
}

class _HeaderStatusScopeState extends State<HeaderStatusScope> {
  _PhoneStatusController? controller;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _PhoneStatusBinding.of(context);
    if (next == controller) return;
    controller?.update(this, false);
    controller = next;
    controller?.update(this, true);
  }

  @override
  void dispose() {
    controller?.update(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PhoneViewport extends StatefulWidget {
  final Widget child;
  final bool? showPreviewStatus;
  const PhoneViewport({super.key, required this.child, this.showPreviewStatus});
  @override
  State<PhoneViewport> createState() => _PhoneViewportState();
}

class _PhoneViewportState extends State<PhoneViewport> {
  final controller = _PhoneStatusController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ![
      TargetPlatform.android,
      TargetPlatform.iOS,
    ].contains(defaultTargetPlatform);
    final preview =
        widget.showPreviewStatus ??
        (kIsWeb && desktop && MediaQuery.sizeOf(context).width <= 640);
    return _PhoneStatusBinding(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        child: widget.child,
        builder: (context, child) {
          final branded = controller.branded;
          final foreground = branded ? Colors.white : const Color(0xFF14261D);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: branded
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                  )
                : SystemUiOverlayStyle.dark,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: branded ? loginHeaderGradient : null,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (preview)
                      DefaultTextStyle(
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 12,
                          color: foreground,
                          decoration: TextDecoration.none,
                        ),
                        child: _PreviewStatusBar(foreground: foreground),
                      ),
                    Expanded(child: child!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewStatusBar extends StatefulWidget {
  final Color foreground;
  const _PreviewStatusBar({required this.foreground});
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.foreground,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: 15,
                color: widget.foreground,
              ),
              const SizedBox(width: 4),
              const Text(
                '4G',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 7),
              Icon(Icons.wifi_rounded, size: 15, color: widget.foreground),
              const SizedBox(width: 7),
              const Text(
                '100%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.battery_full_rounded,
                size: 17,
                color: widget.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
