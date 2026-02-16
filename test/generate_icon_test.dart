import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate app icon from splash screen design', (WidgetTester tester) async {
    // 스플래시 화면과 동일한 디자인
    const size = 1024.0;

    final widget = RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.15),
        ),
        child: const Center(
          child: Icon(
            Icons.face_retouching_natural,
            size: size * 0.5,
            color: Color(0xFF6C63FF),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: widget),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // RepaintBoundary 찾기
    final finder = find.byType(RepaintBoundary).first;
    final renderObject = tester.renderObject(finder) as RenderRepaintBoundary;

    // 이미지로 변환
    final image = await renderObject.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // 저장
    final file = File('assets/icon/app_icon.png');
    await file.writeAsBytes(pngBytes);

    print('✅ App icon generated: ${file.path}');
  });
}
