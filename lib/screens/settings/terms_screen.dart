import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '제1조 (목적)',
            content: '본 약관은 Afterly(이하 "회사")가 제공하는 피부 관리 전후 비교 분석 서비스(이하 "서비스")의 '
                '이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
          ),
          _buildSection(
            title: '제2조 (정의)',
            content: '1. "서비스"란 회사가 제공하는 피부 관리 전후 사진 촬영, 저장, 비교 분석 및 관련 기능을 의미합니다.\n'
                '2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 이용하는 회원 및 비회원을 말합니다.\n'
                '3. "회원"이란 서비스에 회원가입을 한 자로서, 계속적으로 서비스를 이용할 수 있는 자를 말합니다.',
          ),
          _buildSection(
            title: '제3조 (약관의 게시와 개정)',
            content: '1. 회사는 본 약관의 내용을 이용자가 쉽게 알 수 있도록 앱 내에 게시합니다.\n'
                '2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.\n'
                '3. 약관이 개정되는 경우 회사는 개정내용과 적용일자를 명시하여 앱 내 공지사항을 통해 공지합니다.',
          ),
          _buildSection(
            title: '제4조 (서비스의 제공)',
            content: '회사는 다음과 같은 서비스를 제공합니다:\n\n'
                '1. Before/After 사진 촬영 및 저장\n'
                '2. 고객 정보 관리\n'
                '3. 촬영 이미지 비교 분석\n'
                '4. 피부 상태 분석 (참고용)\n'
                '5. 기타 회사가 추가 개발하거나 제휴 계약 등을 통해 제공하는 일체의 서비스',
          ),
          _buildSection(
            title: '제5조 (서비스의 중단)',
            content: '회사는 다음 각 호의 경우 서비스 제공을 일시적으로 중단할 수 있습니다:\n\n'
                '1. 시스템 정기점검, 증설 및 교체를 위해 필요한 경우\n'
                '2. 천재지변, 국가비상사태 등 불가항력적 사유가 있는 경우\n'
                '3. 서비스 설비의 장애 또는 서비스 이용의 폭주 등으로 정상적인 서비스 제공이 어려운 경우\n\n'
                '회사는 서비스 중단의 경우 사전에 공지하며, 부득이한 경우 사후에 공지할 수 있습니다.',
          ),
          _buildSection(
            title: '제6조 (회원가입)',
            content: '1. 이용자는 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 본 약관에 동의한다는 의사표시를 함으로써 회원가입을 신청합니다.\n'
                '2. 회사는 제1항과 같이 회원으로 가입할 것을 신청한 이용자 중 다음 각 호에 해당하지 않는 한 회원으로 등록합니다:\n'
                '   • 타인의 명의를 이용한 경우\n'
                '   • 허위의 정보를 기재한 경우\n'
                '   • 기타 회원으로 등록하는 것이 서비스 운영에 현저히 지장이 있다고 판단되는 경우',
          ),
          _buildSection(
            title: '제7조 (회원 탈퇴 및 자격 상실)',
            content: '1. 회원은 언제든지 탈퇴를 요청할 수 있으며, 회사는 즉시 회원탈퇴를 처리합니다.\n'
                '2. 회원이 다음 각 호의 사유에 해당하는 경우, 회사는 회원자격을 제한 및 정지시킬 수 있습니다:\n'
                '   • 가입 신청 시 허위 내용을 등록한 경우\n'
                '   • 다른 사람의 서비스 이용을 방해하거나 정보를 도용하는 등 질서를 위협하는 경우\n'
                '   • 서비스를 이용하여 법령 또는 본 약관이 금지하는 행위를 하는 경우',
          ),
          _buildSection(
            title: '제8조 (이용자의 의무)',
            content: '1. 이용자는 다음 행위를 하여서는 안 됩니다:\n'
                '   • 신청 또는 변경 시 허위 내용의 등록\n'
                '   • 타인의 정보 도용\n'
                '   • 회사의 서비스 정보의 변경\n'
                '   • 회사가 정한 정보 이외의 정보 등의 송신 또는 게시\n'
                '   • 회사와 기타 제3자의 저작권 등 지적재산권에 대한 침해\n'
                '   • 기타 불법적이거나 부당한 행위\n\n'
                '2. 이용자는 관계법령, 본 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항을 준수하여야 합니다.',
          ),
          _buildSection(
            title: '제9조 (저작권의 귀속)',
            content: '1. 회사가 작성한 저작물에 대한 저작권 및 기타 지적재산권은 회사에 귀속합니다.\n'
                '2. 이용자가 서비스 내에 게시한 게시물(사진 포함)의 저작권은 해당 이용자에게 귀속됩니다.\n'
                '3. 이용자는 서비스를 이용하여 얻은 정보를 회사의 사전 승낙 없이 복제, 송신, 출판, 배포, 방송 등 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 하여서는 안 됩니다.',
          ),
          _buildSection(
            title: '제10조 (면책조항)',
            content: '1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.\n'
                '2. 회사는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여 책임을 지지 않습니다.\n'
                '3. 회사는 이용자가 서비스를 이용하여 기대하는 수익을 상실한 것이나 서비스를 통하여 얻은 자료로 인한 손해에 관하여 책임을 지지 않습니다.\n'
                '4. 본 서비스의 피부 분석 결과는 참고용이며, 의학적 진단이나 치료 목적으로 사용될 수 없습니다. 전문적인 피부 진단은 피부과 전문의와 상담하시기 바랍니다.',
          ),
          _buildSection(
            title: '부칙',
            content: '본 약관은 2026년 2월 14일부터 적용됩니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
