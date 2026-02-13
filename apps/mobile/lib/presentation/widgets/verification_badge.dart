import 'package:flutter/material.dart';

enum VerificationStatus {
  verified,
  pending,
  unverified,
  rejected,
}

enum VerificationBadgeSize {
  small,
  medium,
  large,
}

class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final VerificationBadgeSize size;
  final bool showLabel;
  final String? customLabel;

  const VerificationBadge({
    super.key,
    required this.status,
    this.size = VerificationBadgeSize.medium,
    this.showLabel = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    if (showLabel) {
      return _buildWithLabel(config);
    }

    return _buildIcon(config);
  }

  Widget _buildIcon(_BadgeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        color: config.iconColor,
        size: config.iconSize,
      ),
    );
  }

  Widget _buildWithLabel(_BadgeConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.padding * 1.5,
        vertical: config.padding * 0.8,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: config.iconColor,
            size: config.iconSize * 0.9,
          ),
          SizedBox(width: config.padding * 0.5),
          Text(
            customLabel ?? config.label,
            style: TextStyle(
              color: config.iconColor,
              fontSize: config.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    // Size multipliers
    final double sizeMultiplier = switch (size) {
      VerificationBadgeSize.small => 0.7,
      VerificationBadgeSize.medium => 1.0,
      VerificationBadgeSize.large => 1.4,
    };

    final baseIconSize = 16.0 * sizeMultiplier;
    final basePadding = 6.0 * sizeMultiplier;
    final baseFontSize = 12.0 * sizeMultiplier;

    // Status-based configuration
    return switch (status) {
      VerificationStatus.verified => _BadgeConfig(
          icon: Icons.verified,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF3B82F6), // Blue
          label: 'Verified',
          iconSize: baseIconSize,
          padding: basePadding,
          fontSize: baseFontSize,
        ),
      VerificationStatus.pending => _BadgeConfig(
          icon: Icons.pending,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFFF59E0B), // Orange
          label: 'Pending',
          iconSize: baseIconSize,
          padding: basePadding,
          fontSize: baseFontSize,
        ),
      VerificationStatus.unverified => _BadgeConfig(
          icon: Icons.shield_outlined,
          iconColor: Colors.white,
          backgroundColor: Colors.grey.shade400,
          label: 'Not Verified',
          iconSize: baseIconSize,
          padding: basePadding,
          fontSize: baseFontSize,
        ),
      VerificationStatus.rejected => _BadgeConfig(
          icon: Icons.cancel,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFFEF4444), // Red
          label: 'Rejected',
          iconSize: baseIconSize,
          padding: basePadding,
          fontSize: baseFontSize,
        ),
    };
  }

  /// Helper to convert string status to enum
  static VerificationStatus statusFromString(String? status) {
    if (status == null) return VerificationStatus.unverified;
    return switch (status.toLowerCase()) {
      'verified' => VerificationStatus.verified,
      'pending' => VerificationStatus.pending,
      'rejected' => VerificationStatus.rejected,
      _ => VerificationStatus.unverified,
    };
  }
}

class _BadgeConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final double iconSize;
  final double padding;
  final double fontSize;

  _BadgeConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.iconSize,
    required this.padding,
    required this.fontSize,
  });
}
