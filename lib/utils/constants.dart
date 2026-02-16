import 'package:flutter/material.dart';

class AppColors {
  // 스플래시 화면과 동일한 톤
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF5850E6);
  static const accent = Color(0xFF9C96FF);
  static const background = Color(0xFFF8F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFE5E5EB);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF8E8E9E);
  static const success = Color(0xFF4CAF50); // 스플래시 그라디언트 색상
  static const warning = Color(0xFFE5A44D);
  static const error = Color(0xFFD95B5B);
  static const guideOk = Color(0xFF4CAF50);
  static const guideWarning = Color(0xFFE5A44D);
  static const guideBad = Color(0xFFD95B5B);
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // 다크 배경용 (카메라/비교 화면)
  static const bodyDark = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );
  static const captionDark = TextStyle(
    fontSize: 12,
    color: Color(0xFF9E9EB8),
  );
}
