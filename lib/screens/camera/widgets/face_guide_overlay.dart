import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../utils/face_guide_filter.dart';
import '../../../utils/face_guide_painter.dart';

/// 카메라 화면과 비교 화면에서 공통으로 사용하는 얼굴 가이드 오버레이
/// - 카메라 화면: showMessage=true (촬영 안내 메시지 + 디버그 정보 표시)
/// - 비교 화면: showMessage=false (가이드 외곽선만 표시)
class FaceGuideOverlay extends StatelessWidget {
  // ML Kit 얼굴 감지 결과 (카메라 화면에서 전달, 비교 화면에서는 null)
  final FilterResult? filterResult;

  // 촬영 가능 상태 → 가이드 색상 결정 (초록/노랑/빨강)
  final bool canShoot;

  // 자동 촬영 카운트다운 숫자 (null이면 숨김)
  final int? countdown;

  // 상태 메시지 표시 여부 (비교 화면에서는 불필요)
  final bool showMessage;

  const FaceGuideOverlay({
    super.key,
    this.filterResult,
    required this.canShoot,
    this.countdown,
    this.showMessage = true,  // 기본값: 표시 (카메라 화면 기본 동작)
  });

  @override
  Widget build(BuildContext context) {
    // referenceSize: 가이드 비율 계산에 사용할 기준 크기
    // 어떤 부모 위젯에 배치되든 항상 전체 화면 비율로 가이드를 그리기 위해 screenSize를 넘김
    final screenSize = MediaQuery.sizeOf(context);
    final guideColor = _getGuideColor();

    return Stack(
      // expand: 부모 영역 전체를 차지해 이미지/카메라 프리뷰 위에 정확히 오버레이
      fit: StackFit.expand,
      children: [
        // 얼굴 윤곽 가이드 (CustomPaint + SizedBox.expand 조합)
        // child: SizedBox.expand → CustomPaint가 부모 크기를 정확히 채우도록 강제
        // referenceSize → painter가 화면 크기 기준으로 가이드 비율을 계산
        CustomPaint(
          painter: FaceGuidePainter(
            color: guideColor,
            opacity: 0.6,
            strokeWidth: canShoot ? 3.5 : 3.0,  // 촬영 가능 시 선 굵게
            showGlow: true,
            referenceSize: screenSize,
          ),
          child: const SizedBox.expand(),
        ),

        // 상태 메시지 (카메라 화면 전용)
        // filterResult가 null이면 기본 안내 문구 표시
        if (showMessage)
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

        // 자동 촬영 카운트다운 (canShoot 상태에서 1s 홀드 후 3→2→1 표시)
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

        // 얼굴 감지 디버그 정보 (개발/튜닝용)
        // 얼굴이 감지된 경우에만 roll/yaw/pitch/ratio 수치와 통과 여부 표시
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

  // 촬영 상태에 따라 가이드 색상 결정
  // canShoot=true  → 초록 (촬영 가능)
  // 얼굴 미감지    → 빨강 (얼굴 없음)
  // 그 외          → 노랑 (각도/거리 조정 필요)
  Color _getGuideColor() {
    if (canShoot) return AppColors.guideOk;
    if (filterResult == null || !filterResult!.faceDetected) {
      return AppColors.guideBad;
    }
    return AppColors.guideWarning;
  }
}
