import 'package:flutter/material.dart';

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
            icon: Icons.info_outline,
            iconColor: const Color(0xFF6366F1),
            title: '1. 수집하는 개인정보',
            content: 'Afterly는 다음과 같은 개인정보를 수집합니다:\n\n'
                '• 회원가입 시: 이메일 주소, 비밀번호\n'
                '• 소셜 로그인 시: 이름, 이메일 주소, 프로필 사진 (선택)\n'
                '• 서비스 이용 시: 고객 정보, 촬영 사진, 촬영 일시\n\n'
                '모든 정보는 서비스 제공을 위한 최소한의 정보만 수집합니다.',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.policy_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: '2. 개인정보의 이용 목적',
            content: '수집된 개인정보는 다음의 목적으로만 사용됩니다:\n\n'
                '• 회원 가입 및 관리\n'
                '• 서비스 제공 및 운영\n'
                '• Before/After 사진 관리 및 비교 분석\n'
                '• 고객 문의 응대\n'
                '• 서비스 개선 및 통계 분석',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.folder_outlined,
            iconColor: const Color(0xFF06B6D4),
            title: '3. 개인정보의 보관 및 파기',
            content: '개인정보는 다음과 같이 보관 및 파기됩니다:\n\n'
                '• 보관 기간: 회원 탈퇴 시까지\n'
                '• 파기 방법: 전자적 파일 형태는 기술적 방법을 사용하여 복구 불가능하게 삭제\n'
                '• 회원 탈퇴 시 모든 개인정보는 즉시 삭제됩니다\n\n'
                '단, 관련 법령에 의해 보관이 필요한 경우 법정 기간 동안 보관 후 파기합니다.',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.group_outlined,
            iconColor: const Color(0xFF10B981),
            title: '4. 개인정보의 제3자 제공',
            content: 'Afterly는 이용자의 개인정보를 제3자에게 제공하지 않습니다.\n\n'
                '단, 다음의 경우 예외로 합니다:\n'
                '• 이용자가 사전에 동의한 경우\n'
                '• 법령의 규정에 의하거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 요구가 있는 경우',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.security_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: '5. 개인정보 보호를 위한 기술적 대책',
            content: 'Afterly는 개인정보 보호를 위해 다음과 같은 기술적 대책을 시행하고 있습니다:\n\n'
                '• Firebase Authentication을 통한 안전한 인증\n'
                '• Firebase Security Rules를 통한 데이터 접근 제어\n'
                '• 모든 데이터는 암호화되어 저장\n'
                '• HTTPS를 통한 안전한 데이터 전송\n'
                '• 비밀번호는 암호화되어 저장되며, 관리자도 확인 불가',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFFEC4899),
            title: '6. 이용자의 권리',
            content: '이용자는 다음과 같은 권리를 가집니다:\n\n'
                '• 개인정보 열람 요구권\n'
                '• 개인정보 정정 요구권\n'
                '• 개인정보 삭제 요구권\n'
                '• 개인정보 처리 정지 요구권\n\n'
                '앱 내 설정 메뉴에서 언제든지 본인의 정보를 확인하고 수정하거나 계정을 삭제할 수 있습니다.',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.mail_outline,
            iconColor: const Color(0xFF3B82F6),
            title: '7. 문의처',
            content: '개인정보 처리방침에 대한 문의사항이 있으시면 아래로 연락주시기 바랍니다:\n\n'
                '이메일: support@afterly.app',
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            icon: Icons.update_outlined,
            iconColor: const Color(0xFF64748B),
            title: '8. 개인정보 처리방침 변경',
            content: '본 개인정보 처리방침은 법령, 정책 또는 보안기술의 변경에 따라 내용이 추가, 삭제 및 수정될 수 있습니다. '
                '변경 사항은 앱 내 공지사항을 통해 고지됩니다.\n\n'
                '최종 수정일: 2026년 2월 14일',
          ),
          const SizedBox(height: 8),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
