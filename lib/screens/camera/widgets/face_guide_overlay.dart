import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../utils/face_guide_filter.dart';
import '../../../utils/face_guide_painter.dart';

class FaceGuideOverlay extends StatelessWidget {
  final FilterResult? filterResult;
  final bool canShoot;
  final int? countdown;

  const FaceGuideOverlay({
    super.key,
    this.filterResult,
    required this.canShoot,
    this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final guideColor = _getGuideColor();

    return Stack(
      children: [
        // 얼굴 가이드 오버레이
        CustomPaint(
          size: size,
          painter: FaceGuidePainter(
            color: guideColor,
            opacity: 0.6,
            strokeWidth: canShoot ? 3.5 : 3.0,
            showGlow: true,
          ),
        ),

        // 상태 메시지
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filterResult?.primaryMessage ?? '얼굴을 화면에 맞춰주세요',
                style: TextStyle(
                  color: canShoot ? AppColors.guideOk : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // 카운트다운
        if (countdown != null)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // 디버그 정보 (개발 중 튜닝용)
        if (filterResult != null && filterResult!.faceDetected)
          Positioned(
            bottom: 140,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _debugRow('Roll', filterResult!.smoothRoll, filterResult!.rollOk),
                  _debugRow('Yaw', filterResult!.smoothYaw, filterResult!.yawOk),
                  _debugRow('Pitch', filterResult!.smoothPitch, filterResult!.pitchOk),
                  _debugRow('Ratio', filterResult!.smoothRatio, filterResult!.ratioOk),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _debugRow(String label, double value, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          size: 12,
          color: ok ? AppColors.guideOk : AppColors.guideBad,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Color _getGuideColor() {
    if (canShoot) return AppColors.guideOk;
    if (filterResult == null || !filterResult!.faceDetected) {
      return AppColors.guideBad;
    }
    return AppColors.guideWarning;
  }
}

