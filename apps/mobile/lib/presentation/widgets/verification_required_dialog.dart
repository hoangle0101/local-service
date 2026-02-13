import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/presentation/widgets/minimalist_widgets.dart';
import '../../core/theme/app_colors.dart';

class VerificationRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? phone;
  final bool canSkip;
  final VoidCallback? onVerifySuccess;

  const VerificationRequiredDialog({
    super.key,
    this.title = 'Phone Verification Required',
    this.message =
        'Please verify your phone number to continue with this action.',
    this.phone,
    this.canSkip = true,
    this.onVerifySuccess,
  });

  @override
  Widget build(BuildContext context) {
    return MinDialog(
      title: title == 'Phone Verification Required'
          ? 'Yêu cầu xác minh điện thoại'
          : title,
      message: message ==
              'Please verify your phone number to continue with this action.'
          ? 'Vui lòng xác minh số điện thoại của bạn để tiếp tục thực hiện hành động này.'
          : message,
      icon: Icons.phone_android_rounded,
      content: _buildBenefits(),
      primaryLabel: 'Xác minh ngay',
      onPrimaryPressed: () => _handleVerify(context),
      secondaryLabel: canSkip ? 'Để sau' : null,
      onSecondaryPressed: () => Navigator.of(context).pop(false),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lợi ích khi xác minh:',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Bảo mật tài khoản của bạn',
            'Sử dụng dịch vụ nhanh chóng',
            'Nhận hỗ trợ ưu tiên',
            'Tránh các tin nhắn rác',
          ].map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _handleVerify(BuildContext context) async {
    Navigator.of(context).pop(true);

    // Navigate to OTP verification
    final result = await context.push('/otp-verify', extra: {
      'phone': phone ?? '',
      'purpose': 'verify_phone',
    });

    // If verification was successful, call the callback
    if (result == true && onVerifySuccess != null) {
      onVerifySuccess!();
    }
  }

  /// Show the dialog and return true if user verified, false if skipped
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? phone,
    bool canSkip = true,
    VoidCallback? onVerifySuccess,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: canSkip,
      builder: (context) => VerificationRequiredDialog(
        title: title ?? 'Xác minh số điện thoại',
        message: message ?? 'Vui lòng xác minh số điện thoại để tiếp tục.',
        phone: phone,
        canSkip: canSkip,
        onVerifySuccess: onVerifySuccess,
      ),
    );

    return result ?? false;
  }
}
