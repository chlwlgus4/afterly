import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../utils/constants.dart';

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
      appBar: AppBar(title: const Text('앱 정보')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          // 앱 아이콘
          const Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 20,
                      spreadRadius: -8,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Image(
                    image: AssetImage('assets/icon/app_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 앱 이름
          const Text(
            'Afterly',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 부제
          Text(
            'Before/After 피부 관리 분석',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.65,
              ),
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
                  applicationIcon: const Image(
                    image: AssetImage('assets/icon/app_icon.png'),
                    width: 48,
                    height: 48,
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.65,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
