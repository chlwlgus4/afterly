import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '개인정보 처리방침',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context: context,
            icon: Icons.business_center_outlined,
            iconColor: AppColors.primary,
            title: '제1조 (개인정보처리자 정보)',
            content:
                '본 서비스의 개인정보처리자는 다음과 같습니다.\n\n'
                '• 서비스명: Afterly\n'
                '• 운영형태: 개인 운영\n'
                '• 문의 이메일: support@afterly.app',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.info_outline,
            iconColor: AppColors.accent,
            title: '제2조 (수집하는 개인정보)',
            content:
                'Afterly는 다음과 같은 개인정보를 수집합니다.\n\n'
                '• 회원가입 시: 이메일 주소\n'
                '• 소셜 로그인 시: 이름, 이메일 주소, 프로필 사진 (선택)\n'
                '• 서비스 이용 시: 촬영 사진, 촬영 일시, 앱 버전 및 기기 정보 (서비스 오류 분석 목적)\n\n'
                '비밀번호는 Firebase Authentication을 통해 안전하게 관리되며, '
                '운영자는 비밀번호를 직접 저장하거나 열람하지 않습니다.\n\n'
                '모든 정보는 서비스 제공을 위한 최소한의 범위에서 수집됩니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.policy_outlined,
            iconColor: AppColors.accent,
            title: '제3조 (개인정보의 이용 목적)',
            content:
                '수집된 개인정보는 다음의 목적으로만 사용됩니다.\n\n'
                '• 회원 가입 및 관리\n'
                '• 서비스 제공 및 운영\n'
                '• Before/After 사진 관리 및 비교 분석\n'
                '• 고객 문의 응대\n'
                '• 서비스 개선 및 통계 분석',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.folder_outlined,
            iconColor: AppColors.coral,
            title: '제4조 (개인정보의 보관 및 파기)',
            content:
                '개인정보는 다음과 같이 보관 및 파기됩니다.\n\n'
                '• 보관 기간: 회원 탈퇴 시까지\n'
                '• 탈퇴 시 계정 정보 및 업로드한 사진 데이터는 즉시 삭제됩니다\n'
                '• 전자적 파일은 복구 불가능한 방법으로 삭제됩니다\n\n'
                '단, 관련 법령에 따라 일정 기간 보관이 필요한 경우 해당 기간 동안 보관 후 파기합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.group_outlined,
            iconColor: AppColors.mint,
            title: '제5조 (개인정보의 제3자 제공)',
            content:
                'Afterly는 이용자의 개인정보를 제3자에게 제공하지 않습니다.\n\n'
                '단, 다음의 경우 예외로 합니다.\n'
                '• 이용자가 사전에 동의한 경우\n'
                '• 법령의 규정에 의하거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 요구가 있는 경우',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.handshake_outlined,
            iconColor: AppColors.warning,
            title: '제6조 (개인정보 처리 위탁)',
            content:
                'Afterly는 원활한 서비스 제공을 위해 다음과 같이 개인정보 처리 업무를 외부에 위탁하고 있습니다.\n\n'
                '• 위탁업체: Google LLC\n'
                '• 제공 서비스: Firebase Authentication, Firebase Storage\n'
                '• 위탁 내용: 회원 인증, 데이터 저장 및 관리\n\n'
                '위탁업체는 관련 법령에 따라 개인정보를 안전하게 처리합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.public_outlined,
            iconColor: AppColors.cherry,
            title: '제7조 (개인정보의 국외 이전)',
            content:
                '본 서비스는 Firebase 서비스를 이용하고 있으며, 일부 개인정보는 '
                '국외(미국 등)에 위치한 서버에서 처리될 수 있습니다.\n\n'
                '• 이전 항목: 이메일, 서비스 이용 데이터\n'
                '• 이전 목적: 회원 인증 및 데이터 저장\n'
                '• 이전 시기: 서비스 이용 시 수시 이전\n'
                '• 이전 방법: 암호화된 네트워크를 통한 전송\n'
                '• 보유 및 이용 기간: 회원 탈퇴 시까지',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.face_outlined,
            iconColor: AppColors.primaryLight,
            title: '제8조 (얼굴 감지 및 사진 처리 안내)',
            content:
                'Afterly는 Before/After 비교 기능 제공을 위해 카메라 및 얼굴 감지 기능을 사용합니다.\n\n'
                '• 얼굴 감지는 Google ML Kit을 사용합니다\n'
                '• 얼굴 특징 데이터는 서버에 저장되지 않습니다\n'
                '• 분석은 자동 처리 기반의 참고용 정보 제공 목적입니다\n'
                '• 생체정보를 별도로 수집하거나 저장하지 않습니다',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.security_outlined,
            iconColor: AppColors.primaryDark,
            title: '제9조 (개인정보 보호를 위한 기술적 대책)',
            content:
                'Afterly는 개인정보 보호를 위해 다음과 같은 기술적 조치를 시행하고 있습니다.\n\n'
                '• Firebase Security Rules를 통한 데이터 접근 제어\n'
                '• HTTPS 기반 암호화 통신\n'
                '• 인증 정보는 Firebase를 통해 안전하게 관리\n'
                '• 접근 권한 최소화 및 관리적 보호 조치 시행',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.info,
            title: '제10조 (이용자의 권리)',
            content:
                '이용자는 다음과 같은 권리를 가집니다.\n\n'
                '• 개인정보 열람 요구권\n'
                '• 개인정보 정정 요구권\n'
                '• 개인정보 삭제 요구권\n'
                '• 개인정보 처리 정지 요구권\n\n'
                '앱 내 설정 메뉴에서 언제든지 본인의 정보를 확인하고 수정하거나 계정을 삭제할 수 있습니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.mail_outline,
            iconColor: AppColors.mint,
            title: '제11조 (문의처)',
            content:
                '개인정보 처리방침에 대한 문의사항이 있으시면 아래로 연락주시기 바랍니다.\n\n'
                '이메일: support@afterly.app',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.update_outlined,
            iconColor: AppColors.steel,
            title: '제12조 (개인정보 처리방침 변경)',
            content:
                '본 개인정보 처리방침은 법령, 정책 또는 보안기술의 변경에 따라 내용이 추가, 삭제 및 수정될 수 있습니다. '
                '변경 사항은 앱 내 공지사항을 통해 고지됩니다.\n\n'
                '최종 수정일: 2026년 2월 14일',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                height: 1.6,
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
