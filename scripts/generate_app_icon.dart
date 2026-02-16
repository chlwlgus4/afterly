import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  // 1024x1024 크기의 앱 아이콘 생성 (iOS App Store 크기)
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // 배경색: 흰색
  final whiteColor = img.ColorRgb8(255, 255, 255);
  img.fill(image, color: whiteColor);

  // 중앙 좌표
  final centerX = size ~/ 2;
  final centerY = size ~/ 2;

  // 아이콘 색상: 보라색
  final iconColor = img.ColorRgb8(108, 99, 255); // #6C63FF

  // 스플래시 화면과 동일한 디자인: 큰 "A" 텍스트
  // "A"를 간단한 도형으로 그리기

  // A의 왼쪽 선
  _drawThickLine(image,
    centerX - size ~/ 5, centerY + size ~/ 4,  // 시작점 (왼쪽 아래)
    centerX, centerY - size ~/ 4,              // 끝점 (상단 중앙)
    size ~/ 20, iconColor);

  // A의 오른쪽 선
  _drawThickLine(image,
    centerX, centerY - size ~/ 4,              // 시작점 (상단 중앙)
    centerX + size ~/ 5, centerY + size ~/ 4,  // 끝점 (오른쪽 아래)
    size ~/ 20, iconColor);

  // A의 중간 가로선
  _drawThickLine(image,
    centerX - size ~/ 10, centerY + size ~/ 20,  // 왼쪽
    centerX + size ~/ 10, centerY + size ~/ 20,  // 오른쪽
    size ~/ 20, iconColor);

  // PNG로 저장
  final pngBytes = img.encodePng(image);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);

  print('✅ App icon generated: assets/icon/app_icon.png');
}

void _drawThickLine(img.Image image, int x1, int y1, int x2, int y2, int thickness, img.Color color) {
  // Bresenham's line algorithm with thickness
  final dx = (x2 - x1).abs();
  final dy = (y2 - y1).abs();
  final sx = x1 < x2 ? 1 : -1;
  final sy = y1 < y2 ? 1 : -1;
  var err = dx - dy;

  var x = x1;
  var y = y1;

  while (true) {
    // Draw thick point
    for (var dy = -thickness ~/ 2; dy <= thickness ~/ 2; dy++) {
      for (var dx = -thickness ~/ 2; dx <= thickness ~/ 2; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
          image.setPixel(nx, ny, color);
        }
      }
    }

    if (x == x2 && y == y2) break;

    final e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x += sx;
    }
    if (e2 < dx) {
      err += dx;
      y += sy;
    }
  }
}

