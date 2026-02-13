import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../atoms/custom_button.dart';

class AppHeader extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback? onLogout;

  const AppHeader({
    super.key,
    this.isAuthenticated = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo/Brand
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home_repair_service,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ServiceHub',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            // Auth Buttons
            if (!isAuthenticated)
              Row(
                children: [
                  CustomButton(
                    text: 'Login',
                    variant: ButtonVariant.text,
                    size: ButtonSize.small,
                    onPressed: () {
                      context.push('/login');
                    },
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Sign Up',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.small,
                    onPressed: () {
                      context.push('/register/role');
                    },
                  ),
                ],
              )
            else
              CustomButton(
                text: 'Logout',
                variant: ButtonVariant.outline,
                size: ButtonSize.small,
                onPressed: onLogout,
              ),
          ],
        ),
      ),
    );
  }
}
