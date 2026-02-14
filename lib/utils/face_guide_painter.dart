import 'dart:math';
import 'package:flutter/material.dart';

/// 카메라 화면 + 비교 화면에서 공용으로 사용하는 얼굴 가이드 페인터
class FaceGuidePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double strokeWidth;
  final bool showGlow;

  FaceGuidePainter({
    this.color = Colors.white,
    this.opacity = 1.0,
    this.strokeWidth = 3.0,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;  // 중심 위치
    final w = size.width * 0.42;    // 너비 추가 축소 (0.50 → 0.42)
    final h = size.height * 0.28;   // 높이 추가 축소 (0.35 → 0.28)

    final facePath = _buildFacePath(cx, cy, w, h);

    // 글로우 효과 (바깥 빛)
    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(facePath, glowPaint);
    }

    // 메인 외곽선
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.9 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(facePath, mainPaint);

    // 보조선
    final topY = cy - h * 0.50;
    final chinY = cy + h * 0.50;
    final cheekHW = w * 0.50;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 중앙 세로선
    _drawDashedLine(canvas, Offset(cx, topY + 15), Offset(cx, chinY - 12), dashPaint);

    // 눈 기준 가로선
    final eyeLineY = cy - h * 0.15;
    _drawDashedLine(
      canvas,
      Offset(cx - cheekHW * 0.8, eyeLineY),
      Offset(cx + cheekHW * 0.8, eyeLineY),
      dashPaint,
    );

    // 코 위치 가로선 (짧게)
    final noseY = cy + h * 0.08;
    _drawDashedLine(
      canvas,
      Offset(cx - cheekHW * 0.25, noseY),
      Offset(cx + cheekHW * 0.25, noseY),
      Paint()
        ..color = color.withValues(alpha: 0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path _buildFacePath(double cx, double cy, double w, double h) {
    final path = Path();

    // 사람 얼굴 비율: 이마가 넓고 턱으로 갈수록 자연스럽게 좁아지는 계란형
    final topY = cy - h * 0.55; // 정수리
    final templeY = cy - h * 0.12; // 관자놀이
    final cheekY = cy + h * 0.02; // 광대
    final jawY = cy + h * 0.28; // 턱선
    final chinY = cy + h * 0.52; // 턱 끝

    final foreheadHW = w * 0.56; // 이마 반폭
    final templeHW = w * 0.57; // 관자놀이 반폭 (가장 넓음)
    final cheekHW = w * 0.565; // 광대 반폭
    final jawHW = w * 0.42; // 턱선 반폭
    final chinHW = w * 0.10; // 턱 끝 반폭 (둥근 턱)

    path.moveTo(cx, topY);

    // ── 좌측 ──
    // 정수리 → 관자놀이 (이마: 둥근 곡선)
    path.cubicTo(
      cx - foreheadHW * 0.40, topY,
      cx - templeHW, topY + h * 0.08,
      cx - templeHW, templeY,
    );
    // 관자놀이 → 광대 (부드러운 볼록 곡선)
    path.cubicTo(
      cx - templeHW, templeY + h * 0.12,
      cx - cheekHW * 1.02, cheekY - h * 0.10,
      cx - cheekHW, cheekY,
    );
    // 광대 → 턱선 (자연스럽게 좁아짐)
    path.cubicTo(
      cx - cheekHW * 0.96, cheekY + h * 0.12,
      cx - jawHW * 1.15, jawY - h * 0.08,
      cx - jawHW, jawY,
    );
    // 턱선 → 턱 끝 (둥근 U라인)
    path.cubicTo(
      cx - jawHW * 0.80, jawY + h * 0.10,
      cx - chinHW * 2.0, chinY - h * 0.02,
      cx - chinHW, chinY,
    );

    // 턱 끝 둥근 곡선 (대칭, 넓은 호)
    path.cubicTo(
      cx - chinHW * 0.5, chinY + h * 0.01,
      cx + chinHW * 0.5, chinY + h * 0.01,
      cx + chinHW, chinY,
    );

    // ── 우측 (좌측 대칭) ──
    path.cubicTo(
      cx + chinHW * 2.0, chinY - h * 0.02,
      cx + jawHW * 0.80, jawY + h * 0.10,
      cx + jawHW, jawY,
    );
    path.cubicTo(
      cx + jawHW * 1.15, jawY - h * 0.08,
      cx + cheekHW * 0.96, cheekY + h * 0.12,
      cx + cheekHW, cheekY,
    );
    path.cubicTo(
      cx + cheekHW * 1.02, cheekY - h * 0.10,
      cx + templeHW, templeY + h * 0.12,
      cx + templeHW, templeY,
    );
    path.cubicTo(
      cx + templeHW, topY + h * 0.08,
      cx + foreheadHW * 0.40, topY,
      cx, topY,
    );

    path.close();
    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 5.0;

    final dirX = end.dx - start.dx;
    final dirY = end.dy - start.dy;
    final magnitude = sqrt(dirX * dirX + dirY * dirY);
    if (magnitude == 0) return;
    final nX = dirX / magnitude;
    final nY = dirY / magnitude;

    final path = Path();
    double currentX = start.dx;
    double currentY = start.dy;
    double drawn = 0;
    bool drawing = true;

    while (drawn < magnitude) {
      final segLen = drawing ? dashLength : gapLength;
      final remaining = magnitude - drawn;
      final actualLen = segLen < remaining ? segLen : remaining;

      if (drawing) {
        path.moveTo(currentX, currentY);
        path.lineTo(currentX + nX * actualLen, currentY + nY * actualLen);
      }

      currentX += nX * actualLen;
      currentY += nY * actualLen;
      drawn += actualLen;
      drawing = !drawing;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FaceGuidePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
