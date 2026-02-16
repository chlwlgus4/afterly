import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 정보'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          // 앱 아이콘
          const Center(
            child: Icon(
              Icons.face_retouching_natural,
              size: 100,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),

          // 앱 이름
          const Text(
            'Afterly',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 부제
          const Text(
            'Before/After 피부 관리 분석',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 버전 정보
          _buildInfoCard(
            title: '버전 정보',
            items: [
              _buildInfoRow('버전', _appVersion),
              _buildInfoRow('빌드 번호', _buildNumber),
            ],
          ),
          const SizedBox(height: 16),

          // 개발자 정보
          _buildInfoCard(
            title: '개발자 정보',
            items: [
              _buildInfoRow('개발', 'Afterly Team'),
              _buildInfoRow('문의', 'support@afterly.app'),
            ],
          ),
          const SizedBox(height: 16),

          // 설명
          _buildInfoCard(
            title: '앱 소개',
            items: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Afterly는 피부 관리 전후 사진을 체계적으로 관리하고 '
                  '비교 분석할 수 있는 전문 관리 앱입니다.\n\n'
                  '얼굴 가이드를 통해 일관된 각도로 촬영하고, '
                  'AI 기반 피부 분석으로 관리 효과를 확인할 수 있습니다.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 라이선스
          Center(
            child: TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Afterly',
                  applicationVersion: _appVersion,
                  applicationIcon: const Icon(
                    Icons.face_retouching_natural,
                    size: 48,
                    color: Color(0xFF6C63FF),
                  ),
                );
              },
              child: const Text('오픈소스 라이선스'),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
