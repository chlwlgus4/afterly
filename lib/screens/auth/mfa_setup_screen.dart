import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String value) {
    return value.replaceAll(' ', '').trim();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingCode = true);

    final authService = ref.read(authServiceProvider);

    await authService.startMfaEnrollment(
      phoneNumber: _normalizePhoneNumber(_phoneController.text),
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _codeSent = true;
          _isSendingCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 코드가 발송되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onVerificationFailed: (message) {
        if (!mounted) return;
        setState(() => _isSendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
      onAutoVerified: () async {
        if (!mounted) return;
        setState(() => _isSendingCode = false);
        ref.invalidate(mfaEnrolledProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('2단계 인증이 자동으로 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/');
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    if (_codeController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 코드 6자리를 입력해주세요.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isVerifyingCode = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.completeMfaEnrollment(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );

      if (!mounted) return;
      ref.invalidate(mfaEnrolledProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2단계 인증이 등록되었습니다.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifyingCode = false);
      }
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final hasMfa = ref.watch(mfaEnrolledProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('2단계 인증 설정'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child:
                  hasMfa
                      ? _buildCompletedView(context)
                      : _buildSetupView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user, size: 80, color: AppColors.success),
        const SizedBox(height: 20),
        const Text(
          '2단계 인증 설정 완료',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('홈으로 이동'),
        ),
      ],
    );
  }

  Widget _buildSetupView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.shield, size: 80, color: AppColors.primary),
          const SizedBox(height: 20),
          const Text(
            '보안을 위해\n2단계 인증을 설정해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '국가번호 포함 전화번호 예시: +821012345678',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_isSendingCode && !_isVerifyingCode,
            decoration: const InputDecoration(
              labelText: '전화번호 (+국가코드)',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              final normalized = _normalizePhoneNumber(value ?? '');
              final regExp = RegExp(r'^\+\d{8,15}$');
              if (!regExp.hasMatch(normalized)) {
                return '국가코드를 포함한 전화번호를 입력해주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isSendingCode || _isVerifyingCode ? null : _sendCode,
            child:
                _isSendingCode
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(_codeSent ? '인증 코드 재전송' : '인증 코드 받기'),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 18),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              enabled: !_isVerifyingCode,
              decoration: const InputDecoration(
                labelText: 'SMS 인증 코드',
                prefixIcon: Icon(Icons.sms),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isVerifyingCode ? null : _verifyCode,
              child:
                  _isVerifyingCode
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('2단계 인증 등록 완료'),
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_isSendingCode || _isVerifyingCode) ? null : _signOut,
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
