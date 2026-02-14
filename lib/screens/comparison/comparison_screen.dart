import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shooting_session.dart';
import '../../providers/database_provider.dart';
import '../../services/image_analysis_service.dart';
import '../../services/image_export_service.dart';
import '../../utils/constants.dart';
import '../../utils/face_guide_painter.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const ComparisonScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  ShootingSession? _session;
  bool _isLoading = true;
  bool _showBefore = true;
  double _sliderPosition = 0.5;
  bool _isSliderMode = false;
  bool _isOverlayMode = false;
  double _overlayOpacity = 0.5;
  bool _isDifferenceMode = false;
  bool _showGuide = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  int _analysisSeconds = 0;
  Timer? _analysisTimer;
  String? _errorMessage;

  // 슬라이더 모드 - Before 이미지 상하 위치 조정
  double _beforeVerticalOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final db = ref.read(databaseServiceProvider);
    final session = await db.getSession(widget.sessionId);

    if (session == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '세션을 찾을 수 없습니다';
      });
      return;
    }

    final beforeExists = session.beforeImagePath != null &&
        await File(session.beforeImagePath!).exists();
    final afterExists = session.afterImagePath != null &&
        await File(session.afterImagePath!).exists();

    if (!beforeExists || !afterExists) {
      setState(() {
        _session = session;
        _isLoading = false;
        _errorMessage = !beforeExists
            ? 'Before 이미지를 찾을 수 없습니다'
            : 'After 이미지를 찾을 수 없습니다';
      });
      return;
    }

    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  Future<void> _runAnalysis() async {
    if (_session == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisSeconds = 0;
    });

    _analysisTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _analysisSeconds++);
      }
    });

    try {
      final service = ImageAnalysisService();
      final result = await service.analyze(
        beforePath: _session!.beforeImagePath!,
        afterPath: _session!.afterImagePath!,
      );

      _analysisTimer?.cancel();

      final db = ref.read(databaseServiceProvider);
      final updatedSession = _session!.copyWith(
        jawlineScore: result.jawlineScore,
        symmetryScore: result.symmetryScore,
        skinToneScore: result.skinToneScore,
        summary: result.summary,
      );
      await db.updateSession(updatedSession);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        context.go('/analysis/${widget.sessionId}');
      }
    } catch (e) {
      _analysisTimer?.cancel();
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 실패: $e')),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_session == null || _isSaving) return;

    // 저장 옵션 선택
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이미지 저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.compare, color: AppColors.primary),
              title: const Text('Before + After 비교 이미지', style: TextStyle(color: Colors.white)),
              subtitle: const Text('두 사진을 나란히 합쳐서 저장', style: TextStyle(color: Color(0xFF9E9EB8))),
              onTap: () => Navigator.pop(context, 'both'),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Before 이미지만', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'before'),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.accent),
              title: const Text('After 이미지만', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'after'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    setState(() => _isSaving = true);

    try {
      if (choice == 'both') {
        await ImageExportService.saveComparison(
          beforePath: _session!.beforeImagePath!,
          afterPath: _session!.afterImagePath!,
        );
      } else if (choice == 'before') {
        await ImageExportService.saveSingle(
          imagePath: _session!.beforeImagePath!,
          label: 'BEFORE',
        );
      } else {
        await ImageExportService.saveSingle(
          imagePath: _session!.afterImagePath!,
          label: 'AFTER',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 앨범에 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('비교')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: AppTextStyles.body),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('전/후 비교', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // 모드 전환 버튼
          IconButton(
            icon: Icon(
              _isOverlayMode
                  ? Icons.layers
                  : _isSliderMode
                      ? Icons.compare
                      : Icons.toggle_on,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                if (!_isSliderMode && !_isOverlayMode) {
                  _isSliderMode = true;
                } else if (_isSliderMode) {
                  _isSliderMode = false;
                  _isOverlayMode = true;
                } else {
                  _isOverlayMode = false;
                }
              });
            },
            tooltip: _isOverlayMode
                ? '토글 모드'
                : _isSliderMode
                    ? '오버레이 모드'
                    : '슬라이더 모드',
          ),
          // 가이드라인 토글
          IconButton(
            icon: Icon(
              Icons.face_retouching_natural,
              color: _showGuide ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _showGuide = !_showGuide),
            tooltip: '가이드라인',
          ),
          // 이미지 저장
          IconButton(
            icon: Icon(
              Icons.save_alt,
              color: _isSaving ? AppColors.textSecondary : AppColors.primary,
            ),
            onPressed: _isSaving || _isAnalyzing ? null : _saveImage,
            tooltip: '이미지 저장',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isOverlayMode
                ? _buildOverlayView()
                : _isSliderMode
                    ? _buildSliderView()
                    : _buildToggleView(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 카메라와 동일한 가이드라인 오버레이 (Positioned.fill)
  Widget _buildGuideOverlay() {
    if (!_showGuide) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: FaceGuidePainter(
            color: AppColors.guideOk,
            opacity: 0.8,
            strokeWidth: 3.0,
            showGlow: true,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition =
                  (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _beforeVerticalOffset =
                  (_beforeVerticalOffset + details.delta.dy).clamp(-100.0, 100.0);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // After 이미지 (전체 배경)
              Image.file(
                File(_session!.afterImagePath!),
                fit: BoxFit.contain,
                width: width,
                height: height,
              ),
              // Before 이미지 (좌측 클리핑 + 상하 오프셋)
              ClipRect(
                clipper: _SliderClipper(_sliderPosition),
                child: Transform.translate(
                  offset: Offset(0, _beforeVerticalOffset),
                  child: Image.file(
                    File(_session!.beforeImagePath!),
                    fit: BoxFit.contain,
                    width: width,
                    height: height,
                  ),
                ),
              ),
              // 가이드라인
              _buildGuideOverlay(),
              // 슬라이더 라인
              Positioned(
                left: width * _sliderPosition - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              // 슬라이더 핸들
              Positioned(
                left: width * _sliderPosition - 20,
                top: height / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left, size: 16, color: AppColors.primary),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              // 레이블
              Positioned(
                top: 16,
                left: 16,
                child: _buildLabel('BEFORE', AppColors.primary),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _buildLabel('AFTER', AppColors.accent),
              ),
              // 상하 오프셋 표시
              if (_beforeVerticalOffset.abs() > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_vert, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '위치 조정: ${_beforeVerticalOffset > 0 ? '+' : ''}${_beforeVerticalOffset.toInt()}px',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _beforeVerticalOffset = 0),
                            child: const Icon(Icons.replay,
                                color: AppColors.accent, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleView() {
    return GestureDetector(
      onTap: () => setState(() => _showBefore = !_showBefore),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.file(
              File(
                _showBefore
                    ? _session!.beforeImagePath!
                    : _session!.afterImagePath!,
              ),
              key: ValueKey(_showBefore),
              fit: BoxFit.contain,
            ),
          ),
          // 가이드라인
          _buildGuideOverlay(),
          // 상단 레이블
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildLabel(
                _showBefore ? 'BEFORE' : 'AFTER',
                _showBefore ? AppColors.primary : AppColors.accent,
              ),
            ),
          ),
          // 하단 토글 버튼
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('BEFORE', true),
                    _buildToggleButton('AFTER', false),
                  ],
                ),
              ),
            ),
          ),
          // 안내 텍스트
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '화면을 탭하여 전환',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // After 이미지 (배경)
        Image.file(
          File(_session!.afterImagePath!),
          fit: BoxFit.contain,
        ),
        // Before 오버레이
        Opacity(
          opacity: _overlayOpacity,
          child: _isDifferenceMode
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.file(
                    File(_session!.beforeImagePath!),
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.difference,
                  ),
                )
              : Image.file(
                  File(_session!.beforeImagePath!),
                  fit: BoxFit.contain,
                  color: AppColors.primary.withValues(alpha: 0.4),
                  colorBlendMode: BlendMode.color,
                ),
        ),
        // 가이드라인
        _buildGuideOverlay(),
        // 레이블
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: _buildLabel(
              _isDifferenceMode ? 'DIFFERENCE' : 'OVERLAY',
              _isDifferenceMode ? AppColors.accent : AppColors.primary,
            ),
          ),
        ),
        // 하단 컨트롤
        Positioned(
          bottom: 16,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 차이 강조 모드 토글
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isDifferenceMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isDifferenceMode
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '겹침',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isDifferenceMode
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isDifferenceMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isDifferenceMode
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '차이 강조',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDifferenceMode
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 투명도 슬라이더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'After',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_overlayOpacity * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Before',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.accent.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _overlayOpacity,
                    onChanged: (v) => setState(() => _overlayOpacity = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isBefore) {
    final isSelected = _showBefore == isBefore;
    return GestureDetector(
      onTap: () => setState(() => _showBefore = isBefore),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isBefore ? AppColors.primary : AppColors.accent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAnalyzing) ...[
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF25253D),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              '분석 중... $_analysisSeconds초 경과 (약 5~10초 소요)',
              style: AppTextStyles.captionDark,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('홈으로'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9E9EB8),
                    side: const BorderSide(color: Color(0xFF25253D)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _runAnalysis,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isAnalyzing ? '분석 중...' : '분석하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double position;
  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) {
    return oldClipper.position != position;
  }
}
