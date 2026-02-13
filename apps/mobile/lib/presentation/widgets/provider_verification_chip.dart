import 'package:flutter/material.dart';
import 'verification_badge.dart';

class ProviderVerificationChip extends StatelessWidget {
  final String verificationStatus;
  final bool showInfoIcon;
  final VoidCallback? onTap;

  const ProviderVerificationChip({
    super.key,
    required this.verificationStatus,
    this.showInfoIcon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = VerificationBadge.statusFromString(verificationStatus);

    // Don't show chip for unverified providers
    if (status == VerificationStatus.unverified) {
      return const SizedBox.shrink();
    }

    final Widget badge = VerificationBadge(
      status: status,
      size: VerificationBadgeSize.small,
      showLabel: true,
      customLabel:
          status == VerificationStatus.verified ? 'Verified Provider' : null,
    );

    if (onTap == null && !showInfoIcon) {
      return badge;
    }

    return InkWell(
      onTap: onTap ?? () => _showVerificationInfo(context, status),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          if (showInfoIcon) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ],
      ),
    );
  }

  void _showVerificationInfo(BuildContext context, VerificationStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            VerificationBadge(
              status: status,
              size: VerificationBadgeSize.medium,
            ),
            const SizedBox(width: 12),
            const Text('Provider Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoText(status),
            const SizedBox(height: 16),
            if (status == VerificationStatus.verified) _buildBenefitsList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(VerificationStatus status) {
    final String text = switch (status) {
      VerificationStatus.verified =>
        'This provider has been verified by our admin team. Their identity, skills, and credentials have been reviewed.',
      VerificationStatus.pending =>
        'This provider\'s verification is currently under review by our admin team.',
      VerificationStatus.rejected =>
        'This provider\'s verification was not approved. Exercise caution when booking.',
      VerificationStatus.unverified =>
        'This provider has not yet been verified by our admin team.',
    };

    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade700, height: 1.5),
    );
  }

  Widget _buildBenefitsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified providers offer:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            'Identity confirmed',
            'Background checked',
            'Skills verified',
            'Higher trust score',
          ].map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(benefit,
                        style: TextStyle(
                            color: Colors.blue.shade900, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
