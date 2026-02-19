import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class AnalysisResult {
  final double jawlineScore;
  final double symmetryScore;
  final double skinToneScore;
  final double eyebrowScore;
  final String summary;

  const AnalysisResult({
    required this.jawlineScore,
    required this.symmetryScore,
    required this.skinToneScore,
    required this.eyebrowScore,
    required this.summary,
  });
}

class ImageAnalysisService {
  /// Before/After 이미지를 Isolate에서 분석 (URL 또는 로컬 경로)
  Future<AnalysisResult> analyze({
    required String beforePath,
    required String afterPath,
  }) async {
    // URL인지 확인
    final isBeforeUrl = beforePath.startsWith('http');
    final isAfterUrl = afterPath.startsWith('http');

    // 이미지 바이트 가져오기
    final beforeBytes =
        isBeforeUrl
            ? await _downloadImage(beforePath)
            : await _readLocalImage(beforePath);
    final afterBytes =
        isAfterUrl
            ? await _downloadImage(afterPath)
            : await _readLocalImage(afterPath);

    final result = await Isolate.run(() {
      return _analyzeInIsolate(beforeBytes, afterBytes);
    });

    return result;
  }

  /// URL에서 이미지 다운로드
  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image from $url');
    }
    return response.bodyBytes;
  }

  /// 로컬 파일 읽기 (하위 호환성)
  Future<Uint8List> _readLocalImage(String path) async {
    // Firebase로 완전히 전환된 후에는 이 부분이 필요 없을 수 있음
    throw UnimplementedError(
      'Local file reading not supported. Use URLs instead.',
    );
  }

  /// Isolate 안에서 실행되는 분석 로직
  static AnalysisResult _analyzeInIsolate(
    Uint8List beforeBytes,
    Uint8List afterBytes,
  ) {
    // 직접 디코드 + 리사이즈 (Command 파이프라인 대신)
    final beforeRaw = img.decodeImage(beforeBytes);
    final afterRaw = img.decodeImage(afterBytes);

    if (beforeRaw == null || afterRaw == null) {
      return const AnalysisResult(
        jawlineScore: 0,
        symmetryScore: 0,
        skinToneScore: 0,
        eyebrowScore: 0,
        summary: '이미지를 분석할 수 없습니다.',
      );
    }

    // 200x200 썸네일로 리사이즈
    final beforeImg = img.copyResize(beforeRaw, width: 200, height: 200);
    final afterImg = img.copyResize(afterRaw, width: 200, height: 200);

    final jawline = _analyzeJawline(beforeImg, afterImg);
    final symmetry = _analyzeSymmetry(beforeImg, afterImg);
    final skinTone = _analyzeSkinTone(beforeImg, afterImg);
    final eyebrow = _analyzeEyebrow(beforeImg, afterImg);
    final summary = _generateSummary(jawline, symmetry, skinTone, eyebrow);

    return AnalysisResult(
      jawlineScore: jawline,
      symmetryScore: symmetry,
      skinToneScore: skinTone,
      eyebrowScore: eyebrow,
      summary: summary,
    );
  }

  static double _analyzeJawline(img.Image before, img.Image after) {
    final h = before.height;
    final w = before.width;
    final jawStart = (h * 0.65).toInt();

    double diffSum = 0;
    int count = 0;

    for (int y = jawStart; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final bP = before.getPixel(x, y);
        final aP = after.getPixel(x, y);
        final bGray = (bP.r * 0.299 + bP.g * 0.587 + bP.b * 0.114);
        final aGray = (aP.r * 0.299 + aP.g * 0.587 + aP.b * 0.114);
        diffSum += (aGray - bGray).abs();
        count++;
      }
    }

    final avgDiff = count > 0 ? diffSum / count : 0;
    return (avgDiff / 50.0 * 100).clamp(0.0, 100.0).roundToDouble();
  }

  static double _analyzeSymmetry(img.Image before, img.Image after) {
    double beforeAsym = _calcAsymmetry(before);
    double afterAsym = _calcAsymmetry(after);
    double improvement = beforeAsym - afterAsym;
    return (50 + improvement * 10).clamp(0.0, 100.0).roundToDouble();
  }

  static double _calcAsymmetry(img.Image image) {
    final w = image.width;
    final h = image.height;
    final halfW = w ~/ 2;
    double leftSum = 0, rightSum = 0;
    int count = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < halfW; x++) {
        final lP = image.getPixel(x, y);
        final rP = image.getPixel(w - 1 - x, y);
        leftSum += (lP.r * 0.299 + lP.g * 0.587 + lP.b * 0.114);
        rightSum += (rP.r * 0.299 + rP.g * 0.587 + rP.b * 0.114);
        count++;
      }
    }

    if (count == 0) return 0;
    return ((leftSum - rightSum) / count).abs();
  }

  static double _analyzeSkinTone(img.Image before, img.Image after) {
    final beforeVar = _calcSkinVariance(before);
    final afterVar = _calcSkinVariance(after);
    double improvement = beforeVar - afterVar;
    return (50 + improvement * 5).clamp(0.0, 100.0).roundToDouble();
  }

  static double _calcSkinVariance(img.Image image) {
    final w = image.width;
    final h = image.height;
    final startX = (w * 0.25).toInt();
    final endX = (w * 0.75).toInt();
    final startY = (h * 0.2).toInt();
    final endY = (h * 0.8).toInt();

    List<double> values = [];
    for (int y = startY; y < endY; y += 2) {
      for (int x = startX; x < endX; x += 2) {
        final p = image.getPixel(x, y);
        values.add((p.r * 0.299 + p.g * 0.587 + p.b * 0.114).toDouble());
      }
    }

    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  static double _analyzeEyebrow(img.Image before, img.Image after) {
    final beforeFeatures = _calcEyebrowFeatures(before);
    final afterFeatures = _calcEyebrowFeatures(after);

    final brightnessDiff =
        (afterFeatures.brightness - beforeFeatures.brightness).abs() / 255.0;
    final contrastDiff =
        (afterFeatures.contrast - beforeFeatures.contrast).abs() / 128.0;
    final edgeDiff =
        (afterFeatures.edgeStrength - beforeFeatures.edgeStrength).abs() /
        255.0;
    final balanceDiff =
        (afterFeatures.leftRightDiff - beforeFeatures.leftRightDiff).abs() /
        255.0;

    final weighted =
        (edgeDiff * 0.4) +
        (contrastDiff * 0.3) +
        (brightnessDiff * 0.2) +
        (balanceDiff * 0.1);

    return (weighted * 180).clamp(0.0, 100.0).roundToDouble();
  }

  static _EyebrowFeatures _calcEyebrowFeatures(img.Image image) {
    final w = image.width;
    final h = image.height;

    final left = _regionStats(
      image: image,
      startX: (w * 0.16).toInt(),
      endX: (w * 0.44).toInt(),
      startY: (h * 0.18).toInt(),
      endY: (h * 0.36).toInt(),
    );
    final right = _regionStats(
      image: image,
      startX: (w * 0.56).toInt(),
      endX: (w * 0.84).toInt(),
      startY: (h * 0.18).toInt(),
      endY: (h * 0.36).toInt(),
    );

    return _EyebrowFeatures(
      brightness: (left.brightness + right.brightness) / 2,
      contrast: (left.contrast + right.contrast) / 2,
      edgeStrength: (left.edgeStrength + right.edgeStrength) / 2,
      leftRightDiff: (left.brightness - right.brightness).abs(),
    );
  }

  static _RegionStats _regionStats({
    required img.Image image,
    required int startX,
    required int endX,
    required int startY,
    required int endY,
  }) {
    double sum = 0;
    double sqSum = 0;
    double edgeSum = 0;
    int count = 0;

    final clampedStartX = startX.clamp(0, image.width - 1);
    final clampedEndX = endX.clamp(1, image.width);
    final clampedStartY = startY.clamp(0, image.height - 1);
    final clampedEndY = endY.clamp(1, image.height);

    for (int y = clampedStartY; y < clampedEndY; y++) {
      for (int x = clampedStartX; x < clampedEndX; x++) {
        final p = image.getPixel(x, y);
        final gray = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).toDouble();
        sum += gray;
        sqSum += gray * gray;
        count++;

        if (x + 1 < clampedEndX) {
          final nx = image.getPixel(x + 1, y);
          final nGray = (nx.r * 0.299 + nx.g * 0.587 + nx.b * 0.114).toDouble();
          edgeSum += (gray - nGray).abs();
        }
        if (y + 1 < clampedEndY) {
          final ny = image.getPixel(x, y + 1);
          final nGray = (ny.r * 0.299 + ny.g * 0.587 + ny.b * 0.114).toDouble();
          edgeSum += (gray - nGray).abs();
        }
      }
    }

    if (count == 0) {
      return const _RegionStats(brightness: 0, contrast: 0, edgeStrength: 0);
    }

    final mean = sum / count;
    final variance = (sqSum / count) - (mean * mean);

    return _RegionStats(
      brightness: mean,
      contrast: sqrt(variance.clamp(0.0, double.infinity)),
      edgeStrength: edgeSum / count,
    );
  }

  static String _generateSummary(
    double jawline,
    double symmetry,
    double skinTone,
    double eyebrow,
  ) {
    final parts = <String>[];

    if (jawline >= 60) {
      parts.add('턱 라인에서 뚜렷한 변화가 관찰되었습니다');
    } else if (jawline >= 40) {
      parts.add('턱 라인에서 미세한 변화가 있습니다');
    }

    if (symmetry >= 60) {
      parts.add('좌우 균형이 개선되었습니다');
    } else if (symmetry >= 40) {
      parts.add('좌우 균형이 유지되고 있습니다');
    }

    if (skinTone >= 60) {
      parts.add('피부 톤 균일도가 향상되었습니다');
    } else if (skinTone >= 40) {
      parts.add('피부 톤에 변화가 있습니다');
    }

    if (eyebrow >= 60) {
      parts.add('눈썹 라인 변화가 뚜렷합니다');
    } else if (eyebrow >= 40) {
      parts.add('눈썹 라인에 변화가 감지됩니다');
    }

    if (parts.isEmpty) {
      return '관리 전후 비교 분석이 완료되었습니다.';
    }

    return '관리 후 ${parts.join(', ')}.';
  }
}

class _EyebrowFeatures {
  final double brightness;
  final double contrast;
  final double edgeStrength;
  final double leftRightDiff;

  const _EyebrowFeatures({
    required this.brightness,
    required this.contrast,
    required this.edgeStrength,
    required this.leftRightDiff,
  });
}

class _RegionStats {
  final double brightness;
  final double contrast;
  final double edgeStrength;

  const _RegionStats({
    required this.brightness,
    required this.contrast,
    required this.edgeStrength,
  });
}
