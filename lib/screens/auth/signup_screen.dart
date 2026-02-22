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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneLocalController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedDialCode = '+82';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneLocalController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _buildE164Phone() {
    final digits = _phoneLocalController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (_selectedDialCode == '+82' && digits.startsWith('0')) {
      return '$_selectedDialCode${digits.substring(1)}';
    }
    return '$_selectedDialCode$digits';
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입 완료! 인증 메일을 보냈습니다. 메일 인증 후 전화번호 인증을 진행해주세요.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(
          '/mfa-setup?phone=${Uri.encodeComponent(_buildE164Phone())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '새 계정 만들기',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: '이메일',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '이메일을 입력해주세요';
                              }
                              if (!value.contains('@')) {
                                return '올바른 이메일 형식이 아닙니다';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 104,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDialCode,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: '코드',
                                  ),
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
                                      _isLoading
                                          ? null
                                          : (value) {
                                            if (value == null) return;
                                            setState(
                                              () => _selectedDialCode = value,
                                            );
                                          },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneLocalController,
                                  decoration: const InputDecoration(
                                    labelText: '휴대폰 번호',
                                    hintText: '1012345678',
                                    prefixIcon: Icon(Icons.phone_android),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    final digits = (value ?? '').replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    );
                                    if (digits.isEmpty) {
                                      return '휴대폰 번호를 입력해주세요';
                                    }
                                    if (digits.length < 7 ||
                                        digits.length > 12) {
                                      return '휴대폰 번호 형식을 확인해주세요';
                                    }
                                    return null;
                                  },
                                  enabled: !_isLoading,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호를 입력해주세요';
                              }
                              if (value.length < 6) {
                                return '비밀번호는 최소 6자 이상이어야 합니다';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: '비밀번호 확인',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                  );
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호 확인을 입력해주세요';
                              }
                              if (value != _passwordController.text) {
                                return '비밀번호가 일치하지 않습니다';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
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
                                      '회원가입',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            child: const Text('이미 계정이 있으신가요? 로그인'),
                          ),
                        ],
                      ),
                    ),
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
