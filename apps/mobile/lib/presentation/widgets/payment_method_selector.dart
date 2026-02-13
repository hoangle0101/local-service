import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Payment method selection widget for booking flow
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;
  final bool showDescription;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                method: 'COD',
                title: 'Tiền mặt',
                subtitle: 'Thanh toán khi hoàn thành',
                icon: Icons.payments_outlined,
                color: Colors.green,
                isSelected: selectedMethod == 'COD',
                onTap: () => onMethodSelected('COD'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodCard(
                method: 'MOMO',
                title: 'MoMo',
                subtitle: 'Ví điện tử',
                icon: Icons.phone_android,
                color: const Color(0xFFAE2070),
                isSelected: selectedMethod == 'MOMO',
                onTap: () => onMethodSelected('MOMO'),
              ),
            ),
          ],
        ),
        if (showDescription) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedMethod == 'COD'
                  ? Colors.green.shade50
                  : const Color(0xFFAE2070).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedMethod == 'COD'
                    ? Colors.green.shade200
                    : const Color(0xFFAE2070).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedMethod == 'COD' ? Icons.info_outline : Icons.security,
                  size: 18,
                  color: selectedMethod == 'COD'
                      ? Colors.green.shade700
                      : const Color(0xFFAE2070),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedMethod == 'COD'
                        ? 'Bạn sẽ thanh toán trực tiếp cho thợ sau khi dịch vụ hoàn thành.'
                        : 'Thanh toán an toàn qua MoMo. Tiền sẽ được giữ đến khi hoàn thành dịch vụ.',
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedMethod == 'COD'
                          ? Colors.green.shade700
                          : const Color(0xFFAE2070),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? color.withOpacity(0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary widget showing price breakdown with platform fee
class PaymentSummaryCard extends StatelessWidget {
  final double servicePrice;
  final double platformFeePercent;
  final String? serviceName;
  final String? providerName;

  const PaymentSummaryCard({
    super.key,
    required this.servicePrice,
    this.platformFeePercent = 0.10, // 10%
    this.serviceName,
    this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    final platformFee = servicePrice * platformFeePercent;
    final totalPrice = servicePrice + platformFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.5),
            AppColors.primaryLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (serviceName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dịch vụ', style: TextStyle(color: Colors.grey.shade700)),
                Flexible(
                  child: Text(
                    serviceName!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (providerName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nhà cung cấp',
                    style: TextStyle(color: Colors.grey.shade700)),
                Text(providerName!,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const Divider(height: 20),
          ],
          _buildPriceRow('Giá dịch vụ', servicePrice),
          const SizedBox(height: 6),
          _buildPriceRow('Phí nền tảng (10%)', platformFee, isSubtle: true),
          const Divider(height: 20),
          _buildPriceRow('Tổng cộng', totalPrice, isBold: true, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isBold = false, bool isSubtle = false, bool isTotal = false}) {
    final formattedAmount = '${_formatNumber(amount)}đ';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSubtle ? Colors.grey.shade600 : AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          formattedAmount,
          style: TextStyle(
            color: isTotal ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}
