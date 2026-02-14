/// EMA(지수이동평균) 스무딩 + 히스테리시스 판정
class EmaFilter {
  final double alpha;
  double _value = 0;
  bool _initialized = false;

  EmaFilter({this.alpha = 0.2});

  double update(double newValue) {
    if (!_initialized) {
      _value = newValue;
      _initialized = true;
    } else {
      _value = alpha * newValue + (1 - alpha) * _value;
    }
    return _value;
  }

  double get value => _value;

  void reset() {
    _initialized = false;
    _value = 0;
  }
}

/// 히스테리시스 판정기: ON/OFF 임계값 분리로 깜빡임 방지
class HysteresisChecker {
  final double onThreshold;
  final double offThreshold;
  bool _isOk = false;

  HysteresisChecker({
    required this.onThreshold,
    required this.offThreshold,
  });

  bool check(double absValue) {
    if (_isOk) {
      if (absValue >= offThreshold) {
        _isOk = false;
      }
    } else {
      if (absValue <= onThreshold) {
        _isOk = true;
      }
    }
    return _isOk;
  }

  bool get isOk => _isOk;

  void reset() {
    _isOk = false;
  }
}

class FaceGuideFilter {
  // EMA filters
  final EmaFilter rollFilter = EmaFilter(alpha: 0.2);
  final EmaFilter yawFilter = EmaFilter(alpha: 0.2);
  final EmaFilter pitchFilter = EmaFilter(alpha: 0.2);
  final EmaFilter faceRatioFilter = EmaFilter(alpha: 0.15);

  // 히스테리시스 checkers — 엄격한 기준으로 동일 조건 촬영 보장
  final HysteresisChecker rollChecker = HysteresisChecker(
    onThreshold: 3.0,    // ON: |roll| ≤ 3°
    offThreshold: 4.5,   // OFF: |roll| ≥ 4.5°
  );
  final HysteresisChecker yawChecker = HysteresisChecker(
    onThreshold: 5.0,    // ON: |yaw| ≤ 5° (좌우 대칭 보장)
    offThreshold: 7.0,   // OFF: |yaw| ≥ 7°
  );
  final HysteresisChecker pitchChecker = HysteresisChecker(
    onThreshold: 5.0,    // ON: |pitch| ≤ 5°
    offThreshold: 7.0,   // OFF: |pitch| ≥ 7°
  );
  final HysteresisChecker faceRatioChecker = HysteresisChecker(
    onThreshold: 0.03,   // faceRatio 허용 편차 (좁게)
    offThreshold: 0.05,
  );

  // Face ratio target range — 좁은 범위로 동일 크기 보장
  static const double faceRatioMin = 0.30;
  static const double faceRatioMax = 0.45;
  static const double faceRatioTarget = 0.37;

  // Brightness range
  static const double brightnessMin = 80;
  static const double brightnessMax = 200;

  /// 모든 필터 업데이트 후 각 조건 판정 결과 반환
  FilterResult update({
    required double rollDeg,
    required double yawDeg,
    required double pitchDeg,
    required double faceRatio,
    required double brightness,
    required bool stable,
    required bool faceDetected,
  }) {
    if (!faceDetected) {
      return FilterResult.noFace();
    }

    // EMA 스무딩 적용
    final smoothRoll = rollFilter.update(rollDeg);
    final smoothYaw = yawFilter.update(yawDeg);
    final smoothPitch = pitchFilter.update(pitchDeg);
    final smoothRatio = faceRatioFilter.update(faceRatio);

    // 히스테리시스 판정
    final rollOk = rollChecker.check(smoothRoll.abs());
    final yawOk = yawChecker.check(smoothYaw.abs());
    final pitchOk = pitchChecker.check(smoothPitch.abs());

    // Face ratio 범위 체크
    final ratioOk = smoothRatio >= faceRatioMin && smoothRatio <= faceRatioMax;

    // Brightness
    final brightnessOk = brightness >= brightnessMin && brightness <= brightnessMax;

    return FilterResult(
      faceDetected: true,
      rollOk: rollOk,
      yawOk: yawOk,
      pitchOk: pitchOk,
      ratioOk: ratioOk,
      brightnessOk: brightnessOk,
      stableOk: stable,
      smoothRoll: smoothRoll,
      smoothYaw: smoothYaw,
      smoothPitch: smoothPitch,
      smoothRatio: smoothRatio,
      brightness: brightness,
    );
  }

  void reset() {
    rollFilter.reset();
    yawFilter.reset();
    pitchFilter.reset();
    faceRatioFilter.reset();
    rollChecker.reset();
    yawChecker.reset();
    pitchChecker.reset();
    faceRatioChecker.reset();
  }
}

class FilterResult {
  final bool faceDetected;
  final bool rollOk;
  final bool yawOk;
  final bool pitchOk;
  final bool ratioOk;
  final bool brightnessOk;
  final bool stableOk;

  final double smoothRoll;
  final double smoothYaw;
  final double smoothPitch;
  final double smoothRatio;
  final double brightness;

  const FilterResult({
    required this.faceDetected,
    required this.rollOk,
    required this.yawOk,
    required this.pitchOk,
    required this.ratioOk,
    required this.brightnessOk,
    required this.stableOk,
    required this.smoothRoll,
    required this.smoothYaw,
    required this.smoothPitch,
    required this.smoothRatio,
    required this.brightness,
  });

  factory FilterResult.noFace() => const FilterResult(
        faceDetected: false,
        rollOk: false,
        yawOk: false,
        pitchOk: false,
        ratioOk: false,
        brightnessOk: true,
        stableOk: true,
        smoothRoll: 0,
        smoothYaw: 0,
        smoothPitch: 0,
        smoothRatio: 0,
        brightness: 128,
      );

  bool get canShoot =>
      faceDetected && rollOk && yawOk && pitchOk && ratioOk && brightnessOk && stableOk;

  String get primaryMessage {
    if (!faceDetected) return '얼굴을 화면에 맞춰주세요';
    if (!ratioOk) {
      if (smoothRatio < FaceGuideFilter.faceRatioMin) return '조금 가까이 와주세요';
      return '조금 멀어져 주세요';
    }
    if (!yawOk) {
      if (smoothYaw > 0) return '얼굴을 왼쪽으로 돌려주세요';
      return '얼굴을 오른쪽으로 돌려주세요';
    }
    if (!pitchOk) {
      if (smoothPitch > 0) return '고개를 조금 내려주세요';
      return '고개를 조금 올려주세요';
    }
    if (!rollOk) return '고개를 똑바로 세워주세요';
    if (!brightnessOk) {
      if (brightness < FaceGuideFilter.brightnessMin) return '조명이 너무 어두워요';
      return '조명이 너무 밝아요';
    }
    if (!stableOk) return '휴대폰을 고정해주세요';
    return '촬영 준비 완료!';
  }
}
