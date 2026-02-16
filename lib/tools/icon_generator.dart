import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 이 파일을 main.dart에서 임시로 import하고 실행해서 아이콘을 생성하세요.
///
/// main.dart에서:
/// import 'tools/icon_generator.dart';
/// void main() => runApp(const IconGeneratorApp());

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Icon Generator')),
        body: const IconGeneratorWidget(),
      ),
    );
  }
}

class IconGeneratorWidget extends StatefulWidget {
  const IconGeneratorWidget({super.key});

  @override
  State<IconGeneratorWidget> createState() => _IconGeneratorWidgetState();
}

class _IconGeneratorWidgetState extends State<IconGeneratorWidget> {
  final GlobalKey _globalKey = GlobalKey();
  String _status = '아래 버튼을 눌러 아이콘을 생성하세요';

  Future<void> _generateIcon() async {
    try {
      setState(() => _status = '생성 중...');

      // RepaintBoundary에서 이미지 캡처
      final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 저장
      final file = File('assets/icon/app_icon.png');
      await file.writeAsBytes(pngBytes);

      setState(() => _status = '✅ 생성 완료: ${file.path}\n\n이제 flutter pub run flutter_launcher_icons를 실행하세요');
    } catch (e) {
      setState(() => _status = '❌ 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 미리보기
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(45),
              ),
              child: const Center(
                child: Icon(
                  Icons.face_retouching_natural,
                  size: 150,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _generateIcon,
            child: const Text('아이콘 생성', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
