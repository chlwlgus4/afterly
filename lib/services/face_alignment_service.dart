import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AlignedFacePair {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;

  const AlignedFacePair({required this.beforeBytes, required this.afterBytes});
}

/// Before/After 원본을 "공정 비교용" 정렬본으로 맞추는 서비스.
/// - 단일 얼굴 기준 회전/크롭/리사이즈
/// - 과한 보정 대신 완만한 톤 정규화만 적용
class FaceAlignmentService {
  FaceAlignmentService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
        ),
      );

  final FaceDetector _faceDetector;
  bool _isClosed = false;

  Future<AlignedFacePair?> alignPair({
    required String beforePath,
    required String afterPath,
  }) async {
    try {
      // 입력이 URL/로컬 혼합이어도 동일 인터페이스로 바이트화.
      final beforeBytes = await _readImageBytes(beforePath);
      final afterBytes = await _readImageBytes(afterPath);

      final alignedBefore = await _alignSingle(beforeBytes);
      final alignedAfter = await _alignSingle(afterBytes);

      if (alignedBefore == null || alignedAfter == null) return null;

      final correctedAfter = _matchToneToReference(
        source: alignedAfter,
        reference: alignedBefore,
      );

      // 네트워크/저장 비용을 줄이기 위해 JPEG로 반환.
      return AlignedFacePair(
        beforeBytes: Uint8List.fromList(
          img.encodeJpg(alignedBefore, quality: 92),
        ),
        afterBytes: Uint8List.fromList(
          img.encodeJpg(correctedAfter, quality: 92),
        ),
      );
    } catch (e) {
      debugPrint('Face alignment failed: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    if (_isClosed) return;
    _isClosed = true;
    await _faceDetector.close();
  }

  Future<img.Image?> _alignSingle(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final detected = await _detectPrimaryFace(bytes);
    if (detected == null) {
      // 얼굴 검출 실패 시에도 비교가 깨지지 않게 중앙 정사각 fallback.
      final fallback = _centerSquareCrop(decoded);
      return img.copyResize(
        fallback,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.cubic,
      );
    }

    img.Image workingImage = decoded;
    _FaceInfo workingFace = detected;

    if (detected.roll.abs() > 1.0) {
      // 기울기(roll)만 1차 보정 후 재검출해 크롭 기준을 안정화.
      final rotated = img.copyRotate(decoded, angle: -detected.roll);
      final rotatedBytes = Uint8List.fromList(
        img.encodeJpg(rotated, quality: 92),
      );
      final redetected = await _detectPrimaryFace(rotatedBytes);
      if (redetected != null) {
        workingImage = rotated;
        workingFace = redetected;
      }
    }

    final cropped = _cropAroundFace(
      image: workingImage,
      faceBounds: workingFace.bounds,
    );

    final resized = img.copyResize(
      cropped,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    );

    return _applyGentleNormalization(resized);
  }

  Future<_FaceInfo?> _detectPrimaryFace(Uint8List bytes) async {
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/face_detect_${DateTime.now().microsecondsSinceEpoch}.jpg';
      tempFile = File(path);
      await tempFile.writeAsBytes(bytes, flush: true);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;

      // 다중 얼굴이면 가장 큰 박스를 메인 얼굴로 사용.
      faces.sort((a, b) {
        final aArea = a.boundingBox.width * a.boundingBox.height;
        final bArea = b.boundingBox.width * b.boundingBox.height;
        return bArea.compareTo(aArea);
      });

      final primary = faces.first;
      return _FaceInfo(
        bounds: primary.boundingBox,
        roll: primary.headEulerAngleZ ?? 0,
      );
    } catch (e) {
      debugPrint('Face detection failed: $e');
      return null;
    } finally {
      if (tempFile != null) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  img.Image _cropAroundFace({
    required img.Image image,
    required Rect faceBounds,
  }) {
    // 얼굴 박스보다 넉넉한 범위(2.3x)로 크롭해 턱/이마를 함께 보존.
    final maxCropSide = math.min(image.width, image.height).toDouble();
    final desiredSide = (math.max(faceBounds.width, faceBounds.height) * 2.3)
        .clamp(128.0, maxCropSide);
    final side = desiredSide.round();

    final centerX = faceBounds.left + faceBounds.width / 2;
    final centerY = faceBounds.top + faceBounds.height / 2;

    final maxLeft = image.width - side;
    final maxTop = image.height - side;

    final left =
        ((centerX - side / 2).round()).clamp(0, math.max(0, maxLeft)) as int;
    final top =
        ((centerY - side / 2).round()).clamp(0, math.max(0, maxTop)) as int;

    if (side <= 1) {
      return _centerSquareCrop(image);
    }

    return img.copyCrop(image, x: left, y: top, width: side, height: side);
  }

  img.Image _centerSquareCrop(img.Image image) {
    final side = math.min(image.width, image.height);
    final left = (image.width - side) ~/ 2;
    final top = (image.height - side) ~/ 2;
    return img.copyCrop(image, x: left, y: top, width: side, height: side);
  }

  img.Image _applyGentleNormalization(img.Image source) {
    // 표준편차/평균 기반 선형 보정으로 과한 피부톤 왜곡을 방지.
    final stats = _lumaStats(source);
    final gain = (48.0 / (stats.std + 1e-6)).clamp(0.85, 1.15);
    final bias = (128.0 - stats.mean * gain).clamp(-18.0, 18.0);

    return _applyLinearTone(source, gain: gain, bias: bias);
  }

  img.Image _matchToneToReference({
    required img.Image source,
    required img.Image reference,
  }) {
    // AFTER를 BEFORE 톤으로 근접시켜 조명 차이만 완화.
    final sourceStats = _lumaStats(source);
    final referenceStats = _lumaStats(reference);

    final gain = (referenceStats.std / (sourceStats.std + 1e-6)).clamp(
      0.9,
      1.15,
    );
    final bias = (referenceStats.mean - sourceStats.mean * gain).clamp(
      -20.0,
      20.0,
    );

    return _applyLinearTone(source, gain: gain, bias: bias);
  }

  img.Image _applyLinearTone(
    img.Image source, {
    required double gain,
    required double bias,
  }) {
    final out = img.Image.from(source);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final r = _clamp255(p.r * gain + bias);
        final g = _clamp255(p.g * gain + bias);
        final b = _clamp255(p.b * gain + bias);
        out.setPixelRgba(x, y, r, g, b, p.a.toInt());
      }
    }

    return out;
  }

  _LumaStats _lumaStats(img.Image image) {
    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final p = image.getPixel(x, y);
        final luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
        sum += luma;
        sumSq += luma * luma;
        count++;
      }
    }

    if (count == 0) {
      return const _LumaStats(mean: 128, std: 1);
    }

    final mean = sum / count;
    final variance = math.max(0, (sumSq / count) - (mean * mean));
    final std = math.sqrt(variance);
    return _LumaStats(mean: mean, std: std);
  }

  int _clamp255(num value) => value.clamp(0, 255).round();

  Future<Uint8List> _readImageBytes(String pathOrUrl) async {
    if (pathOrUrl.startsWith('http')) {
      final response = await http.get(Uri.parse(pathOrUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: $pathOrUrl');
      }
      return response.bodyBytes;
    }
    return File(pathOrUrl).readAsBytes();
  }
}

class _FaceInfo {
  final Rect bounds;
  final double roll;

  const _FaceInfo({required this.bounds, required this.roll});
}

class _LumaStats {
  final double mean;
  final double std;

  const _LumaStats({required this.mean, required this.std});
}
