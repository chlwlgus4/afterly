import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class AnalysisResult {
  final double jawlineScore;
  final double symmetryScore;
  final double skinToneScore;
  final String summary;

  const AnalysisResult({
    required this.jawlineScore,
    required this.symmetryScore,
    required this.skinToneScore,
    required this.summary,
  });
}

class ImageAnalysisService {
  /// Before/After 이미지를 Isolate에서 분석
  Future<AnalysisResult> analyze({
    required String beforePath,
    required String afterPath,
  }) async {
    final beforeBytes = await File(beforePath).readAsBytes();
    final afterBytes = await File(afterPath).readAsBytes();

    final result = await Isolate.run(() {
      return _analyzeInIsolate(beforeBytes, afterBytes);
    });

    return result;
  }

  /// Isolate 안에서 실행되는 분석 로직
  static AnalysisResult _analyzeInIsolate(
      Uint8List beforeBytes, Uint8List afterBytes) {
    // 직접 디코드 + 리사이즈 (Command 파이프라인 대신)
    final beforeRaw = img.decodeImage(beforeBytes);
    final afterRaw = img.decodeImage(afterBytes);

    if (beforeRaw == null || afterRaw == null) {
      return const AnalysisResult(
        jawlineScore: 0,
        symmetryScore: 0,
        skinToneScore: 0,
        summary: '이미지를 분석할 수 없습니다.',
      );
    }

    // 200x200 썸네일로 리사이즈
    final beforeImg = img.copyResize(beforeRaw, width: 200, height: 200);
    final afterImg = img.copyResize(afterRaw, width: 200, height: 200);

    final jawline = _analyzeJawline(beforeImg, afterImg);
    final symmetry = _analyzeSymmetry(beforeImg, afterImg);
    final skinTone = _analyzeSkinTone(beforeImg, afterImg);
    final summary = _generateSummary(jawline, symmetry, skinTone);

    return AnalysisResult(
      jawlineScore: jawline,
      symmetryScore: symmetry,
      skinToneScore: skinTone,
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

  static String _generateSummary(
      double jawline, double symmetry, double skinTone) {
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

    if (parts.isEmpty) {
      return '관리 전후 비교 분석이 완료되었습니다.';
    }

    return '관리 후 ${parts.join(', ')}.';
  }
}
