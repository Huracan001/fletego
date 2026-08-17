import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Temporary wordmark — replace asset later without redesigning screens.
class FletegoBrandMark extends StatelessWidget {
  const FletegoBrandMark({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? FletegoColors.white : FletegoColors.navy;
    final subtitleColor = light
        ? FletegoColors.white.withValues(alpha: 0.75)
        : FletegoColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RouteGlyph(
              color: light ? FletegoColors.white : FletegoColors.primary,
            ),
            const SizedBox(width: FletegoSpacing.sm),
            Text(
              'FLETEGO',
              style:
                  (compact
                          ? FletegoTypography.textTheme.headlineSmall
                          : FletegoTypography.textTheme.displayMedium)
                      ?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'by Pick&Truck',
              style: FletegoTypography.textTheme.labelMedium?.copyWith(
                color: subtitleColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteGlyph extends StatelessWidget {
  const _RouteGlyph({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _RouteGlyphPainter(color)),
    );
  }
}

/// Subtle F / route mark — logistics + movement, not a cartoon truck.
class _RouteGlyphPainter extends CustomPainter {
  _RouteGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width * 0.55,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.85,
        size.height * 0.25,
      );

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.85),
      2.2,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.25),
      2.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
