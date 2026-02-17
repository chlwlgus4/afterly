import 'dart:math';
import 'package:flutter/material.dart';

/// 카메라 화면 + 비교 화면에서 공용으로 사용하는 얼굴 가이드 CustomPainter
///
/// [referenceSize]: 가이드 크기 비율 계산의 기준이 되는 화면 크기
///   - 전달하면: referenceSize 기준으로 가이드 크기(w, h) 계산 → 어떤 부모 크기에도 동일한 비율 유지
///   - null이면: CustomPaint에 전달된 실제 size 기준으로 계산
class FaceGuidePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double strokeWidth;
  final bool showGlow;
  // 가이드 비율 계산의 기준 크기 (전체 화면 크기를 넘겨 일관성 유지)
  final Size? referenceSize;

  FaceGuidePainter({
    this.color = Colors.white,
    this.opacity = 1.0,
    this.strokeWidth = 3.0,
    this.showGlow = true,
    this.referenceSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // cx/cy: 렌더링 영역 기준으로 가이드 중심 좌표 결정
    // w/h: referenceSize(전체 화면) 기준으로 가이드 크기 결정
    //   → 렌더링 영역이 달라도(카메라 전체 화면 vs 비교 화면 일부) 동일한 절대 크기 유지
    final baseSize = referenceSize ?? size;
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final w = baseSize.width * 0.42;
    final h = baseSize.height * 0.28;

    final facePath = _buildFacePath(cx, cy, w, h);

    // 글로우 효과 (외곽선 바깥쪽 빛번짐, blur로 구현)
    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(facePath, glowPaint);
    }

    // 메인 외곽선 (얼굴 윤곽선)
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.9 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(facePath, mainPaint);

    // 보조선 기준점 계산
    final topY = cy - h * 0.50;
    final chinY = cy + h * 0.50;
    final cheekHW = w * 0.50;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 중앙 세로선 (좌우 대칭 기준선)
    _drawDashedLine(canvas, Offset(cx, topY + 15), Offset(cx, chinY - 12), dashPaint);

    // 눈 위치 가로선 (cy 위 15% 지점)
    final eyeLineY = cy - h * 0.15;
    _drawDashedLine(
      canvas,
      Offset(cx - cheekHW * 0.8, eyeLineY),
      Offset(cx + cheekHW * 0.8, eyeLineY),
      dashPaint,
    );

    // 코 위치 가로선 (짧게, 반투명)
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

  // 사람 얼굴 형태의 계란형 Path 생성
  // 이마가 넓고 턱으로 갈수록 좁아지는 곡선을 cubicTo(베지어 곡선)로 표현
  Path _buildFacePath(double cx, double cy, double w, double h) {
    final path = Path();

    // 세로 기준점 (위→아래)
    final topY = cy - h * 0.55;    // 정수리
    final templeY = cy - h * 0.12; // 관자놀이
    final cheekY = cy + h * 0.02;  // 광대
    final jawY = cy + h * 0.28;    // 턱선
    final chinY = cy + h * 0.52;   // 턱 끝

    // 가로 반폭 (절반 너비)
    final foreheadHW = w * 0.56;  // 이마 (중간 너비)
    final templeHW = w * 0.57;    // 관자놀이 (가장 넓은 지점)
    final cheekHW = w * 0.565;    // 광대
    final jawHW = w * 0.42;       // 턱선 (좁아짐)
    final chinHW = w * 0.10;      // 턱 끝 (가장 좁음, 둥글게)

    path.moveTo(cx, topY);

    // ── 좌측 절반 ──
    // 정수리 → 관자놀이: 이마의 둥근 곡선
    path.cubicTo(
      cx - foreheadHW * 0.40, topY,
      cx - templeHW, topY + h * 0.08,
      cx - templeHW, templeY,
    );
    // 관자놀이 → 광대: 볼록한 볼 곡선
    path.cubicTo(
      cx - templeHW, templeY + h * 0.12,
      cx - cheekHW * 1.02, cheekY - h * 0.10,
      cx - cheekHW, cheekY,
    );
    // 광대 → 턱선: 자연스럽게 좁아지는 곡선
    path.cubicTo(
      cx - cheekHW * 0.96, cheekY + h * 0.12,
      cx - jawHW * 1.15, jawY - h * 0.08,
      cx - jawHW, jawY,
    );
    // 턱선 → 턱 끝: 둥근 U라인
    path.cubicTo(
      cx - jawHW * 0.80, jawY + h * 0.10,
      cx - chinHW * 2.0, chinY - h * 0.02,
      cx - chinHW, chinY,
    );

    // 턱 끝 호: 좌우 대칭으로 부드럽게 연결
    path.cubicTo(
      cx - chinHW * 0.5, chinY + h * 0.01,
      cx + chinHW * 0.5, chinY + h * 0.01,
      cx + chinHW, chinY,
    );

    // ── 우측 절반 (좌측 대칭) ──
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

  // 점선 그리기: start→end 방향 벡터를 단위 벡터로 정규화 후
  // dashLength/gapLength 단위로 번갈아 선을 그림
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 5.0;

    final dirX = end.dx - start.dx;
    final dirY = end.dy - start.dy;
    final magnitude = sqrt(dirX * dirX + dirY * dirY);
    if (magnitude == 0) return;

    // 방향 단위 벡터
    final nX = dirX / magnitude;
    final nY = dirY / magnitude;

    final path = Path();
    double currentX = start.dx;
    double currentY = start.dy;
    double drawn = 0;
    bool drawing = true;  // true: 선 그리기, false: 빈 공간

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
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.referenceSize != referenceSize;
  }
}
