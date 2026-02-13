import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A collection of Modern Minimalist widgets for the Local Service Platform.
/// These widgets enforce zero elevation, large border radii, and purposeful whitespace.

class MinCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final BorderSide? border;

  const MinCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: border?.color ?? AppColors.divider.withOpacity(0.5),
          width: border?.width ?? 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: content,
      );
    }

    return content;
  }
}

class MinButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MinButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 20),
              if (icon != null && text.isNotEmpty) const SizedBox(width: 8),
              if (text.isNotEmpty)
                Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          );

    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
            side: BorderSide(color: backgroundColor ?? AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );

    return isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: content,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: content,
          );
  }
}

class MinBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const MinBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class MinTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final Function(String)? onChanged;

  const MinTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.style,
    this.labelStyle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: labelStyle ??
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          textAlign: textAlign,
          onChanged: onChanged,
          style: style ??
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class MinDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool isDestructive;
  final IconData? icon;

  const MinDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.isDestructive = false,
    this.icon,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    required String primaryLabel,
    VoidCallback? onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool isDestructive = false,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => MinDialog(
        title: title,
        message: message,
        content: content,
        primaryLabel: primaryLabel,
        isDestructive: isDestructive,
        icon: icon,
        secondaryLabel: secondaryLabel,
        onPrimaryPressed: () {
          Navigator.of(dialogContext).pop(true);
          if (onPrimaryPressed != null) onPrimaryPressed();
        },
        onSecondaryPressed: () {
          Navigator.of(dialogContext).pop(false);
          if (onSecondaryPressed != null) onSecondaryPressed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDestructive ? AppColors.error : AppColors.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (content != null) ...[
              if (message != null) const SizedBox(height: 16),
              content!,
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      actions: [
        Row(
          children: [
            if (secondaryLabel != null) ...[
              Expanded(
                child: MinButton(
                  text: secondaryLabel!,
                  isPrimary: false,
                  onPressed: onSecondaryPressed ??
                      () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: isDestructive
                  ? GestureDetector(
                      onTap: onPrimaryPressed ??
                          () => Navigator.of(context).pop(true),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    )
                  : MinButton(
                      text: primaryLabel,
                      onPressed: onPrimaryPressed ??
                          () => Navigator.of(context).pop(true),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
