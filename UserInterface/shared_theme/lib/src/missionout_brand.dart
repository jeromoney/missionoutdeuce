import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'missionout_colors.dart';

class MissionOutBackdrop extends StatelessWidget {
  const MissionOutBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MissionOutColors.night,
            MissionOutColors.nightSky,
            MissionOutColors.horizon,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _GlowOrb(
              size: 360,
              color: MissionOutColors.signal.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -180,
            child: _GlowOrb(
              size: 420,
              color: MissionOutColors.ridge.withValues(alpha: 0.32),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ContourPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class MissionOutBrandLockup extends StatelessWidget {
  const MissionOutBrandLockup({
    super.key,
    this.subtitle,
    this.align = CrossAxisAlignment.start,
    this.centered = false,
    this.logoSize = 54,
    this.headlineColor = MissionOutColors.ice,
    this.detailColor = MissionOutColors.fog,
  });

  final String? subtitle;
  final CrossAxisAlignment align;
  final bool centered;
  final double logoSize;
  final Color headlineColor;
  final Color detailColor;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: align,
      children: [
        Text(
          'MissionOut',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: headlineColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: detailColor,
            ),
          ),
        ],
      ],
    );

    if (centered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MissionOutLogo(size: logoSize),
          const SizedBox(height: 16),
          titleBlock,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MissionOutLogo(size: logoSize),
        const SizedBox(width: 16),
        Flexible(child: titleBlock),
      ],
    );
  }
}

class MissionOutLogo extends StatelessWidget {
  const MissionOutLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MissionOutLogoPainter()),
    );
  }
}

class MissionOutStatusDot extends StatelessWidget {
  const MissionOutStatusDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.36),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _MissionOutLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width * 0.28;
    final center = Offset(size.width * 0.5, size.height * 0.27);

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
    canvas.drawCircle(center, radius * 1.45, glow);

    final beamPaint = Paint()
      ..color = MissionOutColors.signal.withValues(alpha: 0.17)
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.32),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      beamPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.72),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      beamPaint,
    );

    final beaconPaint = Paint()..color = MissionOutColors.signal;
    canvas.drawCircle(center, size.width * 0.075, beaconPaint);

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

class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.18 + index * 0.19);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 22) {
        final wave = math.sin((x / size.width * math.pi * 2) + index) * 12;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
