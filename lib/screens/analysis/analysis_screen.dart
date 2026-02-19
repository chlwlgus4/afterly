import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shooting_session.dart';
import '../../providers/firestore_provider.dart';
import '../../utils/constants.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const AnalysisScreen({super.key, required this.sessionId});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  ShootingSession? _session;
  bool _isLoading = true;

  // 비교 화면과 동일하게 정렬본 우선 표시.
  String? get _beforePreviewUrl {
    final aligned = _session?.alignedBeforeUrl;
    if (aligned != null && aligned.isNotEmpty) return aligned;
    return _session?.beforeImageUrl;
  }

  // 비교 화면과 동일하게 정렬본 우선 표시.
  String? get _afterPreviewUrl {
    final aligned = _session?.alignedAfterUrl;
    if (aligned != null && aligned.isNotEmpty) return aligned;
    return _session?.afterImageUrl;
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final firestore = ref.read(firestoreServiceProvider);
    final session = await firestore.getSession(widget.sessionId);
    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient = <Color>[
      isDark ? AppColors.darkBackground : AppColors.background,
      isDark
          ? AppColors.darkSurfaceLight.withValues(alpha: 0.55)
          : AppColors.surfaceTint.withValues(alpha: 0.55),
    ];
    final appBarColor =
        isDark
            ? AppColors.darkSurface.withValues(alpha: 0.92)
            : AppColors.surface.withValues(alpha: 0.95);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null || !_session!.hasAnalysis) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('분석 결과'),
          backgroundColor: appBarColor,
          surfaceTintColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: backgroundGradient,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _session == null
                      ? '촬영 기록을 찾을 수 없습니다.\n기록이 삭제되었을 수 있습니다.'
                      : '분석 데이터가 없습니다.\n비교 화면에서 분석을 먼저 진행해주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('홈으로'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: () => context.go('/comparison/${widget.sessionId}'),
            tooltip: '비교 화면',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 미리보기
              _buildImagePreview(),
              const SizedBox(height: 24),

              // 분석 요약
              _buildSummaryCard(),
              const SizedBox(height: 20),

              // 점수 카드들
              Text(
                '상세 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildScoreCard(
                icon: Icons.face,
                title: '얼굴 라인 변화',
                score: _session!.jawlineScore!,
                description: _getJawlineDescription(_session!.jawlineScore!),
                color: _getScoreColor(_session!.jawlineScore!),
              ),
              const SizedBox(height: 12),
              _buildScoreCard(
                icon: Icons.balance,
                title: '좌우 균형',
                score: _session!.symmetryScore!,
                description: _getSymmetryDescription(_session!.symmetryScore!),
                color: _getScoreColor(_session!.symmetryScore!),
              ),
              const SizedBox(height: 12),
              _buildScoreCard(
                icon: Icons.palette,
                title: '피부 톤 균일도',
                score: _session!.skinToneScore!,
                description: _getSkinToneDescription(_session!.skinToneScore!),
                color: _getScoreColor(_session!.skinToneScore!),
              ),
              if (_session!.eyebrowScore != null) ...[
                const SizedBox(height: 12),
                _buildScoreCard(
                  icon: Icons.brush_outlined,
                  title: '눈썹 라인 변화',
                  score: _session!.eyebrowScore!,
                  description: _getEyebrowDescription(_session!.eyebrowScore!),
                  color: _getScoreColor(_session!.eyebrowScore!),
                ),
              ],

              const SizedBox(height: 32),

              // 하단 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => context.go('/comparison/${widget.sessionId}'),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('비교 다시보기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.22,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home),
                      label: const Text('홈으로'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageFallbackColor =
        isDark ? AppColors.darkSurfaceLight : AppColors.surfaceTint;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          if (_beforePreviewUrl != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _beforePreviewUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: imageFallbackColor,
                            child: Icon(
                              Icons.error,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BEFORE',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          if (_afterPreviewUrl != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _afterPreviewUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: imageFallbackColor,
                            child: Icon(
                              Icons.error,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AFTER',
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.2),
            isDark
                ? AppColors.darkSurfaceLight.withValues(alpha: 0.5)
                : AppColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.4 : 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '분석 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _session!.summary ?? '분석 요약을 생성할 수 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required IconData icon,
    required String title,
    required double score,
    required String description,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 점수 원형
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 5,
                      backgroundColor:
                          isDark
                              ? AppColors.darkSurfaceLight.withValues(
                                alpha: 0.9,
                              )
                              : AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '${score.toInt()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
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
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _getJawlineDescription(double score) {
    if (score >= 70) return '턱 라인에서 뚜렷한 변화가 감지되었습니다';
    if (score >= 40) return '턱 라인에 미세한 변화가 있습니다';
    return '턱 라인 변화가 크지 않습니다';
  }

  String _getSymmetryDescription(double score) {
    if (score >= 70) return '좌우 균형이 크게 개선되었습니다';
    if (score >= 40) return '좌우 균형이 유지되고 있습니다';
    return '좌우 균형에 큰 차이가 없습니다';
  }

  String _getSkinToneDescription(double score) {
    if (score >= 70) return '피부 톤 균일도가 크게 향상되었습니다';
    if (score >= 40) return '피부 톤에 변화가 감지됩니다';
    return '피부 톤 변화가 크지 않습니다';
  }

  String _getEyebrowDescription(double score) {
    if (score >= 70) return '눈썹 라인 변화가 뚜렷하게 관찰됩니다';
    if (score >= 40) return '눈썹 라인에 미세한 변화가 감지됩니다';
    return '눈썹 라인 변화가 크지 않습니다';
  }
}
