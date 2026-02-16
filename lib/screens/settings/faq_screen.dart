import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '자주 묻는 질문',
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
          _buildFaqItem(
            context: context,
            icon: Icons.camera_alt_outlined,
            iconColor: const Color(0xFF6366F1),
            question: '촬영 시 얼굴이 인식되지 않아요',
            answer: '• 충분한 조명이 있는 곳에서 촬영해주세요\n'
                '• 얼굴이 가이드라인 안에 들어가도록 위치를 조정해주세요\n'
                '• 얼굴이 정면을 향하도록 해주세요\n'
                '• 안경이나 마스크를 착용한 경우 인식이 어려울 수 있습니다',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.face_outlined,
            iconColor: const Color(0xFF8B5CF6),
            question: 'Before와 After 사진을 같은 각도로 촬영하려면?',
            answer: '앱의 얼굴 가이드를 사용하세요. '
                '가이드라인에 얼굴을 맞추면 자동으로 동일한 각도와 거리에서 촬영할 수 있습니다. '
                'Before 촬영 시의 가이드를 기억하고 After 촬영 시에도 동일하게 맞춰주세요.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.cloud_outlined,
            iconColor: const Color(0xFF06B6D4),
            question: '촬영한 사진은 어디에 저장되나요?',
            answer: '모든 사진은 Firebase Storage에 안전하게 암호화되어 저장됩니다. '
                '본인만 접근할 수 있으며, 언제든지 삭제할 수 있습니다.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF10B981),
            question: '고객 정보는 어떻게 관리하나요?',
            answer: '고객 정보는 본인의 계정에만 저장되며, 다른 사용자나 제3자와 공유되지 않습니다. '
                '모든 데이터는 Firebase의 보안 규칙으로 보호됩니다.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFF59E0B),
            question: '촬영 기록을 삭제하면 어떻게 되나요?',
            answer: '촬영 기록을 삭제하면 해당 Before/After 사진과 분석 데이터가 '
                '모두 영구적으로 삭제됩니다. 삭제된 데이터는 복구할 수 없으니 신중하게 선택해주세요.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFFEC4899),
            question: '피부 분석 결과가 정확한가요?',
            answer: '피부 분석은 이미지 처리 기술을 사용한 참고용 정보입니다. '
                '전문적인 피부 진단은 피부과 전문의와 상담하시기 바랍니다. '
                '본 앱의 분석 결과는 관리 전후 비교 용도로만 사용하세요.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.sync_outlined,
            iconColor: const Color(0xFF3B82F6),
            question: '다른 기기에서도 데이터를 볼 수 있나요?',
            answer: '동일한 계정으로 로그인하면 모든 기기에서 데이터를 동기화하여 볼 수 있습니다. '
                'Firebase를 통해 실시간으로 동기화됩니다.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.wifi_off_outlined,
            iconColor: const Color(0xFF64748B),
            question: '오프라인에서도 사용할 수 있나요?',
            answer: '촬영은 오프라인에서도 가능하지만, 사진 업로드와 동기화는 '
                '인터넷 연결이 필요합니다. 네트워크에 연결되면 자동으로 업로드됩니다.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            icon: Icons.person_remove_outlined,
            iconColor: const Color(0xFFEF4444),
            question: '계정을 삭제하면 어떻게 되나요?',
            answer: '계정을 삭제하면 모든 고객 정보, 촬영 기록, 사진이 영구적으로 삭제됩니다. '
                '삭제된 데이터는 복구할 수 없으며, 동일한 이메일로 재가입해도 이전 데이터는 복원되지 않습니다.',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String question,
    required String answer,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
          children: [
            Text(
              answer,
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
