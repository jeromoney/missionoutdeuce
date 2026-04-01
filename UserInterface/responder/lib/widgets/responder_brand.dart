import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class ResponderBrandLockup extends StatelessWidget {
  const ResponderBrandLockup({super.key, this.subtitle, this.logoSize = 54});

  final String? subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponderBrandLogo(size: logoSize),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MissionOut',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: MissionOutColors.ice,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: MissionOutColors.fog,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ResponderBrandLogo extends StatelessWidget {
  const ResponderBrandLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ResponderBrandLogoPainter()),
    );
  }
}

class _ResponderBrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width * 0.5, size.height * 0.31);

    final background = Paint()
      ..shader = const LinearGradient(
        colors: [MissionOutColors.nightSky, MissionOutColors.horizon],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.26)),
      background,
    );

    final glow = Paint()
      ..color = MissionOutColors.signal.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, size.width * 0.22, glow);

    void drawBeamArc({
      required double radius,
      required double top,
      required double opacity,
      required double strokeWidth,
    }) {
      final arcRect = Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * top),
        width: radius * 2,
        height: radius * 1.38,
      );

      canvas.drawArc(
        arcRect,
        3.95,
        1.52,
        false,
        Paint()
          ..color = MissionOutColors.signal.withValues(alpha: opacity)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    drawBeamArc(
      radius: size.width * 0.19,
      top: 0.225,
      opacity: 0.34,
      strokeWidth: size.width * 0.04,
    );
    drawBeamArc(
      radius: size.width * 0.28,
      top: 0.17,
      opacity: 0.2,
      strokeWidth: size.width * 0.034,
    );

    final beaconPaint = Paint()..color = MissionOutColors.signal;
    canvas.drawCircle(center, size.width * 0.075, beaconPaint);
    canvas.drawCircle(
      center,
      size.width * 0.11,
      Paint()
        ..color = MissionOutColors.ice.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02,
    );

    final ridgePath = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.58)
      ..lineTo(size.width * 0.38, size.height * 0.66)
      ..lineTo(size.width * 0.52, size.height * 0.42)
      ..lineTo(size.width * 0.69, size.height * 0.62)
      ..lineTo(size.width * 0.85, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final ridgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [MissionOutColors.steel, MissionOutColors.ridge],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawPath(ridgePath, ridgePaint);

    final foregroundPath = Path()
      ..moveTo(0, size.height * 0.9)
      ..lineTo(size.width * 0.26, size.height * 0.7)
      ..lineTo(size.width * 0.44, size.height * 0.82)
      ..lineTo(size.width * 0.62, size.height * 0.6)
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..lineTo(size.width, size.height * 0.66)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(foregroundPath, Paint()..color = MissionOutColors.panel);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
