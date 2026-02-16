import 'package:flutter/material.dart';
import 'tools/icon_generator.dart';

/// 아이콘 생성 전용 앱
///
/// 실행 방법:
/// flutter run -t lib/main_icon_generator.dart
///
/// 버튼을 눌러서 아이콘 생성 후:
/// flutter pub run flutter_launcher_icons

void main() {
  runApp(const IconGeneratorApp());
}
