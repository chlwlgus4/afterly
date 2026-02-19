import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_settings.dart' as models;
import '../../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  bool _hasPasswordProvider() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
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
          // 사용자 정보 카드
          if (user != null)
            Card(
              elevation: 2,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? '사용자',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 일반 설정
          _buildSectionHeader('일반'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _SettingsSwitchItem(
              icon: Icons.notifications_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '알림',
              subtitle: '촬영 알림 및 기타 알림',
              value: settings.notificationsEnabled,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(value);
              },
            ),
            _SettingsItem(
              icon: Icons.palette_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '테마',
              subtitle: _getThemeModeText(settings.themeMode),
              onTap: () => _showThemeDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // 정보
          _buildSectionHeader('정보'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _SettingsItem(
              icon: Icons.info_outline,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '앱 정보',
              subtitle: '버전 $_appVersion',
              onTap: () => context.push('/settings/about'),
            ),
            _SettingsItem(
              icon: Icons.help_outline,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'FAQ',
              subtitle: '자주 묻는 질문',
              onTap: () => context.push('/settings/faq'),
            ),
            _SettingsItem(
              icon: Icons.privacy_tip_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '개인정보 처리방침',
              onTap: () => context.push('/settings/privacy'),
            ),
            _SettingsItem(
              icon: Icons.description_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '이용약관',
              onTap: () => context.push('/settings/terms'),
            ),
          ]),

          const SizedBox(height: 24),

          // 계정
          _buildSectionHeader('계정'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            // 비밀번호 제공자가 있는 경우만 표시
            if (_hasPasswordProvider()) ...[
              _SettingsItem(
                icon: Icons.key,
                iconColor: Theme.of(context).colorScheme.primary,
                title: '비밀번호 변경',
                subtitle: '계정 비밀번호 업데이트',
                onTap: () => context.push('/settings/change-password'),
              ),
            ],
            _SettingsItem(
              icon: Icons.logout,
              iconColor: AppColors.warning,
              title: '로그아웃',
              titleColor: AppColors.warning,
              onTap: () => _showLogoutDialog(),
            ),
            _SettingsItem(
              icon: Icons.delete_forever,
              iconColor: AppColors.error,
              title: '계정 삭제',
              titleColor: AppColors.error,
              onTap: () => _showDeleteAccountDialog(),
            ),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getThemeModeText(models.ThemeMode mode) {
    switch (mode) {
      case models.ThemeMode.light:
        return '라이트 모드';
      case models.ThemeMode.dark:
        return '다크 모드';
      case models.ThemeMode.system:
        return '시스템 설정';
    }
  }

  void _showThemeDialog() {
    final currentTheme = ref.read(settingsProvider).themeMode;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '테마 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThemeOptionTile(
                  icon: Icons.light_mode,
                  title: '라이트 모드',
                  subtitle: '밝은 화면으로 사용',
                  value: models.ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
                _ThemeOptionTile(
                  icon: Icons.dark_mode,
                  title: '다크 모드',
                  subtitle: '어두운 화면으로 사용',
                  value: models.ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
                _ThemeOptionTile(
                  icon: Icons.brightness_auto,
                  title: '시스템 설정',
                  subtitle: '기기 설정에 따라 자동',
                  value: models.ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              '로그아웃 하시겠습니까?',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await ref.read(authServiceProvider).signOut();
                  if (!mounted) return;
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '계정 삭제',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.\n\n정말로 계정을 삭제하시겠습니까?',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await ref.read(authServiceProvider).deleteAccount();
                    if (!mounted) return;
                    context.go('/login');
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('계정 삭제 실패: $e'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }
}

// 설정 아이템 위젯
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          titleColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// 스위치 설정 아이템 위젯
class _SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// 테마 옵션 타일
class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final models.ThemeMode value;
  final models.ThemeMode groupValue;
  final ValueChanged<models.ThemeMode?>? onChanged;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged?.call(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
