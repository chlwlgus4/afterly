import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class MfaSignInScreen extends ConsumerStatefulWidget {
  const MfaSignInScreen({super.key});

  @override
  ConsumerState<MfaSignInScreen> createState() => _MfaSignInScreenState();
}

class _MfaSignInScreenState extends ConsumerState<MfaSignInScreen> {
  final _codeController = TextEditingController();
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  String? _verificationId;
  int? _resendToken;
  PhoneMultiFactorInfo? _selectedHint;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode(MultiFactorResolver resolver) async {
    final hint = _selectedHint;
    if (hint == null) return;

    setState(() => _isSendingCode = true);

    final authService = ref.read(authServiceProvider);
    await authService.sendMfaSignInCode(
      resolver: resolver,
      hint: hint,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
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
        ref.read(pendingMfaResolverProvider.notifier).state = null;
        context.go('/');
      },
    );
  }

  Future<void> _verifyCode(MultiFactorResolver resolver) async {
    if (_verificationId == null || _codeController.text.trim().length < 6) {
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
      await authService.resolveMfaSignIn(
        resolver: resolver,
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      if (!mounted) return;
      ref.read(pendingMfaResolverProvider.notifier).state = null;
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

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(pendingMfaResolverProvider);

    if (resolver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('2단계 인증 로그인')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('2단계 인증 세션이 만료되었습니다. 다시 로그인해주세요.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('로그인으로 이동'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final phoneHints =
        resolver.hints.whereType<PhoneMultiFactorInfo>().toList();
    if (phoneHints.isNotEmpty && _selectedHint == null) {
      _selectedHint = phoneHints.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('2단계 인증 로그인')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_clock,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '2단계 인증이 필요합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  if (phoneHints.isEmpty)
                    const Text(
                      '등록된 전화번호 인증 수단을 찾지 못했습니다.\n관리자에게 문의해주세요.',
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    DropdownButtonFormField<PhoneMultiFactorInfo>(
                      value: _selectedHint,
                      decoration: const InputDecoration(
                        labelText: '인증 수단',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      items:
                          phoneHints
                              .map(
                                (hint) => DropdownMenuItem(
                                  value: hint,
                                  child: Text(hint.phoneNumber),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _isSendingCode || _isVerifyingCode
                              ? null
                              : (value) =>
                                  setState(() => _selectedHint = value),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _isSendingCode || _isVerifyingCode
                              ? null
                              : () => _sendCode(resolver),
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
                              : Text(
                                _verificationId == null
                                    ? '인증 코드 받기'
                                    : '인증 코드 재전송',
                              ),
                    ),
                    if (_verificationId != null) ...[
                      const SizedBox(height: 12),
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
                        onPressed:
                            _isVerifyingCode
                                ? null
                                : () => _verifyCode(resolver),
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
                                : const Text('로그인 완료'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ref.read(pendingMfaResolverProvider.notifier).state =
                          null;
                      context.go('/login');
                    },
                    child: const Text('다시 로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
