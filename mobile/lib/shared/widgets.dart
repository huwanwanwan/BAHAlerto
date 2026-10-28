import 'package:flutter/material.dart';

const primaryGreen = Color(0xFF078443);
const ink = Color(0xFF005C38);
const lightGreen = Color(0xFF34A853);
const warningOrange = Color(0xFFFF9F1C);
const dangerRed = Color(0xFFF44336);
const mutedText = Color(0xFF596B61);

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFDDE8E1)),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class PageBody extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const PageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(color: mutedText, height: 1.5)),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

class Tag extends StatelessWidget {
  final String text;
  final bool warning;
  const Tag(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1D7) : const Color(0xFFEAF5EE),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (warning) ...[
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF805300),
            size: 16,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: warning ? const Color(0xFF805300) : ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
