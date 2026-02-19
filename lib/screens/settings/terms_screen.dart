import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '이용약관',
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
            icon: Icons.article_outlined,
            iconColor: AppColors.primary,
            title: '제1조 (목적)',
            content:
                '본 약관은 Afterly(이하 "운영자")가 제공하는 피부 관리 전후 비교 및 분석 서비스(이하 "서비스")의 '
                '이용과 관련하여 운영자와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.business_outlined,
            iconColor: AppColors.accent,
            title: '제2조 (운영자 정보)',
            content:
                '본 서비스는 개인 개발자가 운영하는 서비스입니다.\n\n'
                '서비스명: Afterly\n'
                '운영형태: 개인 운영\n'
                '문의 이메일: support@afterly.app',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.description_outlined,
            iconColor: AppColors.coral,
            title: '제3조 (정의)',
            content:
                '1. "서비스"란 운영자가 제공하는 피부 관리 전후 사진 촬영, 저장, 비교 및 분석 기능을 의미합니다.\n'
                '2. "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.\n'
                '3. "회원"이란 서비스에 회원가입을 완료한 자를 말합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.edit_document,
            iconColor: AppColors.mint,
            title: '제4조 (약관의 효력 및 변경)',
            content:
                '1. 본 약관은 앱 내에 게시함으로써 효력이 발생합니다.\n'
                '2. 운영자는 관련 법령을 위반하지 않는 범위에서 약관을 개정할 수 있습니다.\n'
                '3. 변경 시 적용일자 및 내용을 사전에 공지합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.apps_outlined,
            iconColor: AppColors.warning,
            title: '제5조 (서비스의 내용)',
            content:
                '운영자는 다음과 같은 기능을 제공합니다.\n\n'
                '1. Before/After 사진 촬영 및 저장\n'
                '2. 촬영 이미지 비교 기능\n'
                '3. 피부 상태 분석 기능 (참고용 정보 제공)\n'
                '4. 기타 운영자가 추가 개발하는 기능',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.person_add_outlined,
            iconColor: AppColors.cherry,
            title: '제6조 (회원가입)',
            content:
                '1. 이용자는 약관에 동의함으로써 회원가입을 신청합니다.\n'
                '2. 운영자는 다음의 경우 가입을 제한할 수 있습니다.\n'
                '   • 타인의 명의를 도용한 경우\n'
                '   • 허위 정보를 기재한 경우\n'
                '   • 서비스 운영을 방해하는 경우\n'
                '3. 만 14세 미만의 아동은 법정대리인의 동의 없이 회원가입을 할 수 없습니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.person_remove_outlined,
            iconColor: AppColors.error,
            title: '제7조 (회원 탈퇴 및 데이터 삭제)',
            content:
                '1. 회원은 언제든지 탈퇴할 수 있습니다.\n'
                '2. 탈퇴 시 계정 정보 및 업로드한 사진 데이터는 즉시 삭제됩니다.\n'
                '3. 단, 법령에 따라 보관이 필요한 경우 해당 기간 동안 보관 후 삭제됩니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.rule_outlined,
            iconColor: AppColors.info,
            title: '제8조 (이용자의 의무)',
            content:
                '이용자는 다음 행위를 하여서는 안 됩니다.\n\n'
                '• 허위 정보 등록\n'
                '• 타인의 권리 침해\n'
                '• 불법 콘텐츠 업로드\n'
                '• 서비스 운영 방해',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.copyright_outlined,
            iconColor: AppColors.accent,
            title: '제9조 (저작권)',
            content:
                '1. 서비스에 대한 저작권은 운영자에게 귀속됩니다.\n'
                '2. 이용자가 업로드한 사진의 저작권은 이용자에게 귀속됩니다.\n'
                '3. 이용자는 서비스 제공 및 기능 구현(사진 저장, 비교, 자동 분석 등)을 위하여 '
                '운영자가 해당 콘텐츠를 처리하는 것에 동의합니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.cloud_outlined,
            iconColor: AppColors.primaryLight,
            title: '제10조 (외부 서비스 이용)',
            content:
                '1. 본 서비스는 Firebase Authentication 및 Firebase Storage 등 '
                '외부 클라우드 서비스를 이용하여 운영됩니다.\n'
                '2. 외부 서비스의 장애로 인한 서비스 중단에 대해 운영자는 고의 또는 중대한 과실이 없는 한 책임을 지지 않습니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.power_settings_new_outlined,
            iconColor: AppColors.warning,
            title: '제11조 (서비스 중단)',
            content:
                '다음의 경우 서비스가 일시 중단될 수 있습니다.\n\n'
                '• 시스템 점검\n'
                '• 천재지변\n'
                '• 클라우드 서비스 장애\n'
                '• 기타 불가항력 사유',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: AppColors.coral,
            title: '제12조 (면책)',
            content:
                '1. 운영자는 이용자의 귀책사유로 인한 손해에 대해 책임을 지지 않습니다.\n'
                '2. 피부 분석 결과는 단순 참고용 정보이며, 의학적 진단, 치료 또는 의료행위를 대체하지 않습니다.\n'
                '3. 의료적 판단이 필요한 경우 반드시 전문의와 상담하시기 바랍니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.gavel_outlined,
            iconColor: AppColors.primaryDark,
            title: '제13조 (준거법 및 관할)',
            content:
                '1. 본 약관은 대한민국 법령에 따릅니다.\n'
                '2. 분쟁이 발생할 경우 대한민국 민사소송법에 따른 관할 법원에 따릅니다.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.steel,
            title: '부칙',
            content: '본 약관은 2026년 2월 14일부터 시행됩니다.',
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
