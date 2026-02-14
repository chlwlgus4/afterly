import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceGuideMetrics {
  final double rollDeg;
  final double yawDeg;
  final double pitchDeg;
  final double faceRatio;
  final double brightness;
  final bool stable;
  final bool faceDetected;

  const FaceGuideMetrics({
    this.rollDeg = 0,
    this.yawDeg = 0,
    this.pitchDeg = 0,
    this.faceRatio = 0,
    this.brightness = 128,
    this.stable = true,
    this.faceDetected = false,
  });

  factory FaceGuideMetrics.fromFace({
    required Face face,
    required double imageHeight,
    required double imageWidth,
    required bool isStable,
  }) {
    final boundingBox = face.boundingBox;
    final faceHeight = boundingBox.height;
    final ratio = faceHeight / imageHeight;

    return FaceGuideMetrics(
      rollDeg: face.headEulerAngleZ ?? 0,
      yawDeg: face.headEulerAngleY ?? 0,
      pitchDeg: face.headEulerAngleX ?? 0,
      faceRatio: ratio,
      brightness: 128,
      stable: isStable,
      faceDetected: true,
    );
  }

  FaceGuideMetrics copyWith({double? brightness}) {
    return FaceGuideMetrics(
      rollDeg: rollDeg,
      yawDeg: yawDeg,
      pitchDeg: pitchDeg,
      faceRatio: faceRatio,
      brightness: brightness ?? this.brightness,
      stable: stable,
      faceDetected: faceDetected,
    );
  }
}

enum GuideCondition { ok, tooFar, tooClose, turnLeft, turnRight, lookUp, lookDown, tiltHead, tooDark, tooBright, shaking, noFace }

class GuideStatus {
  final bool canShoot;
  final List<GuideCondition> issues;
  final String message;

  const GuideStatus({
    required this.canShoot,
    required this.issues,
    required this.message,
  });

  factory GuideStatus.notReady(String message, List<GuideCondition> issues) {
    return GuideStatus(canShoot: false, issues: issues, message: message);
  }

  factory GuideStatus.ready() {
    return const GuideStatus(canShoot: true, issues: [], message: '촬영 준비 완료!');
  }
}
