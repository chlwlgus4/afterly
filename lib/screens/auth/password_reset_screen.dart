import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  static const int _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _emailSent = false;
  bool _codeSent = false;

  String? _verificationId;
  int? _resendToken;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldownSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
        return;
      }

      setState(() => _cooldownSeconds--);
    });
  }

  Future<void> _sendVerificationCode() async {
    final emailError = _validateEmail(_emailController.text);
    final phoneError = _validatePhone(_phoneController.text);

    if (emailError != null || phoneError != null) {
      _formKey.currentState?.validate();
      return;
    }
    if (_cooldownSeconds > 0 || _isSendingCode || _isLoading) return;

    setState(() => _isSendingCode = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.startPasswordResetPhoneVerification(
        phoneNumber: _phoneController.text.trim(),
        forceResendingToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _isSendingCode = false;
          });
          _startCooldown();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('인증번호를 전송했습니다.')));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('자동 인증이 완료되었습니다.')));
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationId == null || _verificationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 휴대폰 인증번호를 전송하고 인증을 완료해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmailWithPhone(
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!value.contains('@')) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '휴대폰 번호를 입력해주세요';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return '휴대폰 번호 형식을 확인해주세요';
    }
    return null;
  }

  String? _validateSmsCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '인증번호를 입력해주세요';
    }
    if (value.trim().length < 6) {
      return '인증번호 6자리를 입력해주세요';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? <Color>[AppColors.darkBackground, AppColors.darkSurface]
                    : <Color>[
                      AppColors.background,
                      AppColors.surfaceTint,
                      AppColors.accentSoft.withValues(alpha: 0.6),
                    ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child:
                    _emailSent
                        ? _buildSuccessView(context)
                        : _buildFormView(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            '비밀번호를 잊으셨나요?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '계정 이메일과 MFA에 등록된 휴대폰 번호로\n본인인증 후 재설정 링크를 발송합니다.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '휴대폰 번호',
              hintText: '01012345678',
              prefixIcon: Icon(Icons.phone_android),
            ),
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _smsCodeController,
                  decoration: InputDecoration(
                    labelText: '인증번호',
                    prefixIcon: const Icon(Icons.verified_user),
                    helperText: _codeSent ? '인증번호를 입력해주세요' : '먼저 인증번호를 전송하세요',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateSmsCode,
                  enabled: !_isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed:
                (_isSendingCode || _isLoading || _cooldownSeconds > 0)
                    ? null
                    : _sendVerificationCode,
            child:
                _isSendingCode
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      _cooldownSeconds > 0
                          ? '인증번호 재전송 ($_cooldownSeconds초)'
                          : (_codeSent ? '인증번호 재전송' : '인증번호 전송'),
                    ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_isLoading || !_codeSent) ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      '본인인증 후 재설정 링크 보내기',
                      style: TextStyle(fontSize: 16),
                    ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => context.pop(),
            child: const Text('로그인으로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: AppColors.success),
        const SizedBox(height: 24),
        const Text(
          '이메일을 확인해주세요!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '입력하신 정보가 계정과 일치하면\n비밀번호 재설정 링크를 보냈습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '이메일을 받지 못하셨나요?\n스팸 폴더를 확인해주세요.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('로그인하기', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _codeSent = false;
              _verificationId = null;
              _resendToken = null;
              _cooldownSeconds = 0;
              _emailController.clear();
              _phoneController.clear();
              _smsCodeController.clear();
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('다른 정보로 재시도'),
        ),
      ],
    );
  }
}
