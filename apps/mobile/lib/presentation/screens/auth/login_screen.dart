import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/minimalist_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+')) {
        if (phone.startsWith('0')) {
          phone = '+84${phone.substring(1)}';
        } else if (phone.startsWith('84')) {
          phone = '+$phone';
        } else {
          phone = '+84$phone';
        }
      }

      if (_useOtp) {
        context.read<AuthBloc>().add(
              OtpSendRequested(
                phone: phone,
                purpose: 'login',
              ),
            );
      } else {
        context.read<AuthBloc>().add(
              LoginRequested(
                phone: phone,
                password: _passwordController.text,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.user != null) {
              if (state.user!.isProvider) {
                context.go('/provider/home');
              } else {
                context.go('/user/home');
              }
            } else {
              context.go('/');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng nhập thành công!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is OtpSent) {
            context.push('/verify-otp', extra: {
              'phone': state.phone,
              'purpose': 'login',
              'code': state.code,
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Minimalist Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Chào mừng\nbạn quay lại',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đăng nhập để tiếp tục sử dụng các dịch vụ tiện ích của chúng tôi.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Phone Number
                    MinTextField(
                      label: 'Số điện thoại',
                      hint: 'Nhập số điện thoại của bạn',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon:
                          const Icon(Icons.phone_iphone_rounded, size: 20),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Password (only if not using OTP)
                    if (!_useOtp) ...[
                      MinTextField(
                        label: 'Mật khẩu',
                        hint: 'Nhập mật khẩu của bạn',
                        obscureText: true,
                        controller: _passwordController,
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Login Button
                    MinButton(
                      text: _useOtp ? 'Gửi mã OTP' : 'Đăng nhập',
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 16),

                    // Toggle OTP/Password
                    SizedBox(
                      width: double.infinity,
                      child: MinButton(
                        text:
                            _useOtp ? 'Sử dụng mật khẩu' : 'Đăng nhập bằng OTP',
                        isPrimary: false,
                        onPressed: () {
                          setState(() {
                            _useOtp = !_useOtp;
                          });
                        },
                        isFullWidth: true,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Sign Up Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register/role'),
                            child: Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
