import 'package:flutter/material.dart';
import '../../domain/entities/iot_telemetry_entity.dart';

class LivePpgWaveformWidget extends StatelessWidget {
  final int bpm;
  final bool isFingerDetected;
  final bool isMeasuring;
  final List<IotTelemetryEntity> telemetryHistory;
  final Color primaryColor;

  const LivePpgWaveformWidget({
    super.key,
    required this.bpm,
    required this.isFingerDetected,
    this.isMeasuring = true,
    this.telemetryHistory = const [],
    this.primaryColor = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _PpgWaveformPainter(
        bpm: bpm,
        hasFinger: isFingerDetected,
        isMeasuring: isMeasuring,
        telemetryHistory: telemetryHistory,
        waveColor: primaryColor,
      ),
    );
  }
}

class _PpgWaveformPainter extends CustomPainter {
  final int bpm;
  final bool hasFinger;
  final bool isMeasuring;
  final List<IotTelemetryEntity> telemetryHistory;
  final Color waveColor;

  _PpgWaveformPainter({
    required this.bpm,
    required this.hasFinger,
    required this.isMeasuring,
    required this.telemetryHistory,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.clipRRect(rrect);

    final bgPaint = Paint()..color = const Color(0xFF0A1917);
    canvas.drawRect(rect, bgPaint);

    _drawMedicalGrid(canvas, size);

    final midY = size.height * 0.62;
    final effectiveBpm = hasFinger ? bpm.clamp(40, 220) : 0;

    final path = Path();
    final width = size.width;

    final wavePaint = Paint()
      ..color = hasFinger ? waveColor : Colors.amber.shade400
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = (hasFinger ? waveColor : Colors.amber.shade400).withValues(alpha: 0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    double? leadingHeadX;
    double? leadingHeadY;

    if (!hasFinger || effectiveBpm == 0 || telemetryHistory.isEmpty) {

      path.moveTo(0, midY);
      path.lineTo(width, midY);
      leadingHeadX = width;
      leadingHeadY = midY;
    } else {

      final validPoints = telemetryHistory.where((t) => t.finger && t.bpm > 0).toList();
      if (validPoints.length < 2) {
        path.moveTo(0, midY);
        path.lineTo(width, midY);
        leadingHeadX = width;
        leadingHeadY = midY;
      } else {
        final stepX = width / (validPoints.length - 1);
        const minBpm = 45.0;
        const maxBpm = 180.0;
        final usableHeight = size.height * 0.65;
        final topPadding = size.height * 0.22;

        for (int i = 0; i < validPoints.length; i++) {
          final x = i * stepX;
          final normalized = ((validPoints[i].bpm - minBpm) / (maxBpm - minBpm)).clamp(0.0, 1.0);
          final y = topPadding + (usableHeight * (1.0 - normalized));

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
          leadingHeadX = x;
          leadingHeadY = y;
        }
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wavePaint);

    if (leadingHeadX != null && leadingHeadY != null) {
      final dotGlow = Paint()
        ..color = (hasFinger ? Colors.white : Colors.amber.shade200).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final dotSolid = Paint()..color = hasFinger ? Colors.white : Colors.amber.shade200;

      canvas.drawCircle(Offset(leadingHeadX, leadingHeadY), 5.0, dotGlow);
      canvas.drawCircle(Offset(leadingHeadX, leadingHeadY), 2.5, dotSolid);
    }

    _drawOverlayHUD(canvas, size, effectiveBpm);
  }

  void _drawMedicalGrid(Canvas canvas, Size size) {

    final minorPaint = Paint()
      ..color = const Color(0xFF004D40).withValues(alpha: 0.18)
      ..strokeWidth = 0.5;
    final majorPaint = Paint()
      ..color = const Color(0xFF00796B).withValues(alpha: 0.32)
      ..strokeWidth = 0.8;

    const double step = 26.0;

    for (double x = 0; x <= size.width; x += step) {
      final isMajor = (x / step).round() % 4 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }

    for (double y = 0; y <= size.height; y += step) {
      final isMajor = (y / step).round() % 4 == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }
  }

  void _drawOverlayHUD(Canvas canvas, Size size, int effectiveBpm) {

    final statusText = hasFinger && effectiveBpm > 0
        ? '$effectiveBpm BPM'
        : (hasFinger ? 'ACQUIRING' : 'NO SENSOR CONTACT');
    final statusColor = (hasFinger && effectiveBpm > 0)
        ? const Color(0xFF69F0AE)
        : const Color(0xFFFFB74D);
    final statusBgColor = (hasFinger && effectiveBpm > 0)
        ? const Color(0xFF004D40).withValues(alpha: 0.85)
        : const Color(0xFF3E2723).withValues(alpha: 0.7);

    final statusPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: hasFinger && effectiveBpm > 0 ? '● ' : '○ ',
            style: TextStyle(
              color: statusColor,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgePaddingH = 7.0;
    final badgePaddingV = 3.0;
    final badgeWidth = statusPainter.width + (badgePaddingH * 2);
    final badgeHeight = statusPainter.height + (badgePaddingV * 2);
    final badgeOffset = Offset(size.width - badgeWidth - 10, 8);

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeOffset.dx, badgeOffset.dy, badgeWidth, badgeHeight),
      const Radius.circular(6),
    );

    final badgeBgPaint = Paint()..color = statusBgColor;
    final badgeBorderPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(badgeRRect, badgeBgPaint);
    canvas.drawRRect(badgeRRect, badgeBorderPaint);

    statusPainter.paint(
      canvas,
      Offset(badgeOffset.dx + badgePaddingH, badgeOffset.dy + badgePaddingV),
    );

    final maxTitleWidth = (size.width - badgeWidth - 28).clamp(80.0, size.width);
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'PPG WAVEFORM • 25 mm/s',
        style: TextStyle(
          color: Color(0xFF80CBC4),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxTitleWidth);

    titlePainter.paint(canvas, const Offset(12, 10));
  }

  @override
  bool shouldRepaint(covariant _PpgWaveformPainter oldDelegate) {
    return oldDelegate.bpm != bpm ||
        oldDelegate.hasFinger != hasFinger ||
        oldDelegate.isMeasuring != isMeasuring ||
        oldDelegate.telemetryHistory != telemetryHistory;
  }
}

