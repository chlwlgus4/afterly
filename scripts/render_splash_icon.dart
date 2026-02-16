import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1024x1024 크기로 아이콘 생성
  const size = 1024.0;

  // 스플래시 화면과 동일한 디자인의 위젯 생성
  final widget = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.15), // 둥근 모서리
    ),
    child: Center(
      child: Icon(
        Icons.face_retouching_natural,
        size: size * 0.5,
        color: const Color(0xFF6C63FF),
      ),
    ),
  );

  // 위젯을 이미지로 렌더링
  final image = await _widgetToImage(widget, size);

  // PNG로 저장
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  await File('assets/icon/app_icon.png').writeAsBytes(pngBytes);

  print('✅ App icon generated with Icons.face_retouching_natural');
  exit(0);
}

Future<ui.Image> _widgetToImage(Widget widget, double size) async {
  final repaintBoundary = RenderRepaintBoundary();

  final view = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(
          home: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size,
              height: size,
              child: widget,
            ),
          ),
        ),
      ),
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  final pipelineOwner = PipelineOwner()..rootNode = repaintBoundary;
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final image = await repaintBoundary.toImage(pixelRatio: 1.0);
  return image;
}
