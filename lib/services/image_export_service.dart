import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class ImageExportService {
  /// Before/After 이미지를 나란히 합성 + 워터마크 → 갤러리 저장
  static Future<void> saveComparison({
    required String beforePath,
    required String afterPath,
  }) async {
    // 이미지 로드
    final beforeImage = await _loadImage(beforePath);
    final afterImage = await _loadImage(afterPath);

    // 합성 이미지 크기 계산
    final imgW = beforeImage.width;
    final imgH = beforeImage.height;
    const gap = 4; // 이미지 사이 간격
    const labelH = 80; // 하단 워터마크 영역 높이
    final totalW = imgW * 2 + gap;
    final totalH = imgH + labelH;

    // Canvas에 그리기
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()));

    // 배경 (검정)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Before 이미지
    canvas.drawImage(beforeImage, Offset.zero, Paint());

    // After 이미지
    canvas.drawImage(afterImage, Offset((imgW + gap).toDouble(), 0), Paint());

    // 하단 워터마크 배경
    final labelRect = Rect.fromLTWH(0, imgH.toDouble(), totalW.toDouble(), labelH.toDouble());
    canvas.drawRect(labelRect, Paint()..color = const Color(0xFF1A1A2E));

    // BEFORE 텍스트
    _drawLabel(
      canvas,
      'BEFORE',
      Rect.fromLTWH(0, imgH.toDouble(), imgW.toDouble(), labelH.toDouble()),
      const Color(0xFF6C63FF),
    );

    // AFTER 텍스트
    _drawLabel(
      canvas,
      'AFTER',
      Rect.fromLTWH((imgW + gap).toDouble(), imgH.toDouble(), imgW.toDouble(), labelH.toDouble()),
      const Color(0xFFFF6B6B),
    );

    // PNG 변환
    final picture = recorder.endRecording();
    final image = await picture.toImage(totalW, totalH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('이미지 변환 실패');

    // 임시 파일 저장 후 갤러리로 이동
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${dir.path}/afterly_comparison_$timestamp.png';
    await File(tempPath).writeAsBytes(byteData.buffer.asUint8List());

    await Gal.putImage(tempPath);

    // 임시 파일 정리
    try { await File(tempPath).delete(); } catch (_) {}
  }

  /// 단일 이미지 저장 (BEFORE 또는 AFTER 워터마크 포함)
  static Future<void> saveSingle({
    required String imagePath,
    required String label,
  }) async {
    final image = await _loadImage(imagePath);

    const labelH = 60;
    final totalW = image.width;
    final totalH = image.height + labelH;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()));

    // 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // 이미지
    canvas.drawImage(image, Offset.zero, Paint());

    // 워터마크
    final labelColor = label == 'BEFORE' ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B);
    _drawLabel(
      canvas,
      label,
      Rect.fromLTWH(0, image.height.toDouble(), totalW.toDouble(), labelH.toDouble()),
      labelColor,
    );

    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(totalW, totalH);
    final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('이미지 변환 실패');

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${dir.path}/afterly_${label.toLowerCase()}_$timestamp.png';
    await File(tempPath).writeAsBytes(byteData.buffer.asUint8List());

    await Gal.putImage(tempPath);
    try { await File(tempPath).delete(); } catch (_) {}
  }

  static Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawLabel(Canvas canvas, String text, Rect area, Color color) {
    // 컬러 인디케이터 바
    final barRect = Rect.fromLTWH(area.left, area.top, area.width, 3);
    canvas.drawRect(barRect, Paint()..color = color);

    // 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: area.height * 0.35,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        area.left + (area.width - textPainter.width) / 2,
        area.top + (area.height - textPainter.height) / 2 + 2,
      ),
    );
  }
}
