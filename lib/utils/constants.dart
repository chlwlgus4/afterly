import 'package:flutter/material.dart';

class AppColors {
  // 앱 아이콘의 글로시 핑크 톤
  static const primary = Color(0xFFE8488A);
  static const primaryDark = Color(0xFFC32E6C);
  static const primaryLight = Color(0xFFFF9AC4);
  static const accent = Color(0xFFFF6FA8);
  static const accentSoft = Color(0xFFFFD5E8);
  static const info = Color(0xFFFF77A9);
  static const coral = Color(0xFFFF8A73);
  static const cherry = Color(0xFFD93D7B);
  static const mint = Color(0xFF2EB47D);
  static const steel = Color(0xFF8E8295);

  static const background = Color(0xFFFFF5FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFFFE4EF);
  static const surfaceTint = Color(0xFFFFECF5);
  static const textPrimary = Color(0xFF351A29);
  static const textSecondary = Color(0xFF8D6277);

  static const darkBackground = Color(0xFF170B13);
  static const darkSurface = Color(0xFF261420);
  static const darkSurfaceLight = Color(0xFF3A2232);

  static const success = Color(0xFF2EB47D);
  static const warning = Color(0xFFFF9D5C);
  static const error = Color(0xFFE74E64);

  static const guideOk = success;
  static const guideWarning = warning;
  static const guideBad = error;
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
  static const body = TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // 다크 배경용 (카메라/비교 화면)
  static const bodyDark = TextStyle(fontSize: 16, color: Colors.white);
  static const captionDark = TextStyle(fontSize: 12, color: Color(0xFF9E9EB8));
}
