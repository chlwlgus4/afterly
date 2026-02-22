import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class _DialCodeOption {
  final String code;
  final String label;
  const _DialCodeOption(this.code, this.label);
}

const _dialCodeOptions = <_DialCodeOption>[
  _DialCodeOption('+82', 'KR +82'),
  _DialCodeOption('+1', 'US +1'),
  _DialCodeOption('+81', 'JP +81'),
  _DialCodeOption('+86', 'CN +86'),
  _DialCodeOption('+44', 'UK +44'),
  _DialCodeOption('+61', 'AU +61'),
  _DialCodeOption('+84', 'VN +84'),
  _DialCodeOption('+66', 'TH +66'),
  _DialCodeOption('+63', 'PH +63'),
  _DialCodeOption('+65', 'SG +65'),
];

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneLocalController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedDialCode = '+82';

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.trim().isNotEmpty) {
      final parsed = _splitPhone(widget.initialPhone!);
      _selectedDialCode = parsed.$1;
      _phoneLocalController.text = parsed.$2;
    }
    _phoneLocalController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneLocalController.text.length),
    );
  }

  @override
  void dispose() {
    _phoneLocalController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  (String, String) _splitPhone(String value) {
    final normalized = _normalizePhoneNumber(value);
    for (final option in _dialCodeOptions) {
      if (normalized.startsWith(option.code)) {
        return (option.code, normalized.substring(option.code.length));
      }
    }
    return ('+82', normalized.replaceFirst(RegExp(r'^\+'), ''));
  }

  String _normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;
    if (hasPlus) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (_selectedDialCode == '+82' && digits.startsWith('0')) {
      return '$_selectedDialCode${digits.substring(1)}';
    }
    return '$_selectedDialCode$digits';
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingCode = true);

    final authService = ref.read(authServiceProvider);

    try {
      await authService.refreshCurrentUser();
      final isEmailVerified = authService.currentUser?.emailVerified ?? false;
      if (!isEmailVerified) {
        if (!mounted) return;
        setState(() => _isSendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이메일 인증이 필요합니다. 메일 인증 후 다시 시도해주세요.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
      return;
    }

    await authService.startMfaEnrollment(
      phoneNumber: _normalizePhoneNumber(_phoneLocalController.text),
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

  Future<void> _resendVerificationEmail() async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.sendCurrentUserEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 이메일을 다시 보냈습니다. 메일함을 확인해주세요.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
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
            '국가코드를 선택하고 전화번호를 입력하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: (_isSendingCode || _isVerifyingCode)
                ? null
                : _resendVerificationEmail,
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('인증 메일 다시 보내기'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: DropdownButtonFormField<String>(
                  value: _selectedDialCode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '코드'),
                  items:
                      _dialCodeOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.code,
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  selectedItemBuilder:
                      (context) =>
                          _dialCodeOptions
                              .map(
                                (item) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(item.code),
                                ),
                              )
                              .toList(),
                  onChanged:
                      (_isSendingCode || _isVerifyingCode)
                          ? null
                          : (value) {
                            if (value == null) return;
                            setState(() => _selectedDialCode = value);
                          },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phoneLocalController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isSendingCode && !_isVerifyingCode,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    hintText: '1012345678',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty) {
                      return '전화번호를 입력해주세요.';
                    }
                    if (digits.length < 7 || digits.length > 12) {
                      return '전화번호 형식을 확인해주세요.';
                    }
                    return null;
                  },
                ),
              ),
            ],
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
