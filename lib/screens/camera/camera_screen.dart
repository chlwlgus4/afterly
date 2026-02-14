import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/shooting_session.dart';
import '../../providers/customer_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/storage_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../utils/constants.dart';
import '../../utils/face_guide_filter.dart';
import 'widgets/face_guide_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String sessionId;
  final String shootingType; // 'before' or 'after'

  const CameraScreen({
    super.key,
    required this.customerId,
    required this.sessionId,
    required this.shootingType,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  FaceGuideFilter _guideFilter = FaceGuideFilter();

  bool _isDetecting = false;
  bool _isInitialized = false;
  bool _isFrontCamera = false; // 기본 후면 카메라
  FilterResult? _filterResult;
  bool _canShoot = false;
  DateTime? _canShootSince;
  int? _countdown;
  Timer? _countdownTimer;
  bool _isTakingPicture = false;

  // 흔들림 감지
  StreamSubscription? _accelerometerSubscription;
  final List<double> _recentAccel = [];
  bool _isStable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initAccelerometer();
  }

  @override
  void didUpdateWidget(covariant CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Before→After 전환 시 상태 완전 리셋
    if (oldWidget.shootingType != widget.shootingType) {
      _resetState();
      _cameraController?.dispose();
      _faceDetector?.close();
      _isInitialized = false;
      _initCamera();
    }
  }

  void _resetState() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _guideFilter = FaceGuideFilter();
    _isDetecting = false;
    _filterResult = null;
    _canShoot = false;
    _canShootSince = null;
    _countdown = null;
    _isTakingPicture = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceDetector?.close();
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _switchCamera() async {
    setState(() => _isInitialized = false);
    _cancelCountdown();
    _canShootSince = null;
    _canShoot = false;

    await _cameraController?.stopImageStream().catchError((_) {});
    await _cameraController?.dispose();
    _guideFilter.reset();

    _isFrontCamera = !_isFrontCamera;
    await _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final direction = _isFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    // 프레임 스트림 시작
    await _cameraController!.startImageStream(_processFrame);

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      _recentAccel.add(magnitude);
      if (_recentAccel.length > 5) {
        _recentAccel.removeAt(0);
      }

      if (_recentAccel.length >= 3) {
        double maxDiff = 0;
        for (int i = 1; i < _recentAccel.length; i++) {
          final diff = (_recentAccel[i] - _recentAccel[i - 1]).abs();
          if (diff > maxDiff) maxDiff = diff;
        }
        _isStable = maxDiff < 1.5; // 임계값
      }
    });
  }

  void _processFrame(CameraImage image) async {
    if (_isDetecting || _isTakingPicture) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        final result = _guideFilter.update(
          rollDeg: 0,
          yawDeg: 0,
          pitchDeg: 0,
          faceRatio: 0,
          brightness: 128,
          stable: _isStable,
          faceDetected: false,
        );
        setState(() {
          _filterResult = result;
          _canShoot = false;
          _canShootSince = null;
          _cancelCountdown();
        });
      } else {
        final face = faces.first;

        final result = _guideFilter.update(
          rollDeg: face.headEulerAngleZ ?? 0,
          yawDeg: face.headEulerAngleY ?? 0,
          pitchDeg: face.headEulerAngleX ?? 0,
          faceRatio: face.boundingBox.height / image.height,
          brightness: 128, // MVP: 밝기는 촬영 후 체크
          stable: _isStable,
          faceDetected: true,
        );

        setState(() {
          _filterResult = result;
          _canShoot = result.canShoot;
        });

        // 자동 촬영 로직: canShoot 1초 유지 → 3초 카운트다운
        if (result.canShoot) {
          _canShootSince ??= DateTime.now();

          final duration = DateTime.now().difference(_canShootSince!);
          if (duration.inMilliseconds >= 1000 && _countdown == null) {
            _startCountdown();
          }
        } else {
          _canShootSince = null;
          _cancelCountdown();
        }
      }
    } catch (e) {
      // 무시 - 프레임 스킵
    }

    _isDetecting = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 3);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown = _countdown! - 1;
      });

      if (_countdown! <= 0) {
        timer.cancel();
        _takePicture();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdown != null) {
      setState(() => _countdown = null);
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture || _cameraController == null) return;

    setState(() {
      _isTakingPicture = true;
      _countdown = null;
    });

    try {
      // 이미지 스트림 정지 후 카메라 안정화 대기
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200)); // 500ms → 200ms 단축

      if (!mounted || _cameraController == null) return;

      final xFile = await _cameraController!.takePicture();
      final imageFile = File(xFile.path);

      // 이미지 검증
      if (!await imageFile.exists() || await imageFile.length() == 0) {
        throw Exception('촬영된 이미지가 비어있습니다');
      }

      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 먼저 로컬 이미지로 결과 다이얼로그 표시 (빠른 UX)
      if (mounted) {
        _showCaptureResultWithLocalImage(imageFile.path);
      }

      // 백그라운드에서 Firebase 업로드 및 업데이트
      _uploadImageInBackground(imageFile, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('촬영 실패: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        try {
          await _cameraController!.startImageStream(_processFrame);
        } catch (_) {}
        setState(() => _isTakingPicture = false);
      }
    }
  }

  // 로컬 이미지로 빠르게 결과 표시
  void _showCaptureResultWithLocalImage(String localPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(localPath),
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.shootingType == 'before'
                  ? 'Before 촬영 완료!'
                  : 'After 촬영 완료!',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 재촬영 - 로컬 파일 삭제
              try {
                await File(localPath).delete();
              } catch (e) {
                // 삭제 실패해도 계속 진행
              }
              await _cameraController!.startImageStream(_processFrame);
              setState(() {
                _isTakingPicture = false;
                _guideFilter.reset();
              });
            },
            child: const Text('재촬영'),
          ),
          if (widget.shootingType == 'before')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/');
              },
              child: const Text('나중에 After 촬영'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.shootingType == 'before') {
                context.go('/camera/${widget.customerId}/${widget.sessionId}/after');
              } else {
                context.go('/comparison/${widget.sessionId}');
              }
            },
            child: Text(
              widget.shootingType == 'before' ? 'After 바로 촬영' : '비교하기',
            ),
          ),
        ],
      ),
    );
  }

  // 백그라운드에서 Firebase 업로드
  Future<void> _uploadImageInBackground(File imageFile, String userId) async {
    try {
      // 먼저 세션이 존재하는지 확인
      final firestore = ref.read(firestoreServiceProvider);
      final session = await firestore.getSession(widget.sessionId);

      if (session == null) {
        // 세션이 삭제되었으면 업로드하지 않고 로컬 파일만 삭제
        debugPrint('세션이 삭제되어 업로드를 건너뜁니다: ${widget.sessionId}');
        await imageFile.delete();
        return;
      }

      final storage = ref.read(storageServiceProvider);
      final imageUrl = await storage.uploadImage(
        imageFile: imageFile,
        userId: userId,
        folder: widget.shootingType,
        customFileName: '${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // 임시 파일 삭제
      await imageFile.delete();

      // 다시 한 번 세션 확인 (업로드 중에 삭제될 수 있음)
      final sessionCheck = await firestore.getSession(widget.sessionId);
      if (sessionCheck == null) {
        debugPrint('업로드 중 세션이 삭제됨: ${widget.sessionId}');
        // 이미 업로드된 이미지 삭제
        try {
          await storage.deleteImageByUrl(imageUrl);
        } catch (e) {
          debugPrint('이미지 삭제 실패: $e');
        }
        return;
      }

      // Firestore 업데이트
      ShootingSession updatedSession;
      if (widget.shootingType == 'before') {
        updatedSession = sessionCheck.copyWith(beforeImageUrl: imageUrl);
      } else {
        updatedSession = sessionCheck.copyWith(afterImageUrl: imageUrl);
      }
      await firestore.updateSession(updatedSession);

      // Provider 갱신
      if (mounted) {
        ref.invalidate(sessionListProvider(widget.customerId));
        await ref.read(customerListProvider.notifier).updateLastShooting(widget.customerId);
      }
    } catch (e) {
      debugPrint('백그라운드 업로드 실패: $e');
      // 임시 파일 정리 시도
      try {
        await imageFile.delete();
      } catch (_) {}
    }
  }

  void _navigateNext(ShootingSession session) {
    if (widget.shootingType == 'before') {
      // After 촬영으로 이동
      context.go(
        '/camera/${widget.customerId}/${widget.sessionId}/after',
      );
    } else {
      // 비교 화면으로 이동
      context.go('/comparison/${widget.sessionId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 카메라 프리뷰
          if (_isInitialized && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // 얼굴 가이드 오버레이
          FaceGuideOverlay(
            filterResult: _filterResult,
            canShoot: _canShoot,
            countdown: _countdown,
          ),

          // 상단 바
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/'),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.shootingType == 'before'
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : AppColors.accent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.shootingType == 'before' ? 'BEFORE' : 'AFTER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: _isTakingPicture ? null : _switchCamera,
                ),
              ],
            ),
          ),

          // 하단 수동 촬영 버튼
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _canShoot && !_isTakingPicture ? _takePicture : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _canShoot ? Colors.white : Colors.white38,
                      width: 4,
                    ),
                    color: _canShoot
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canShoot ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
