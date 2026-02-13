import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/payment_datasource.dart';

/// Bottom sheet widget for selecting payment method (COD or MoMo)
/// Used when booking status is 'pending_payment'
class PaymentMethodSheet extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> invoice;
  final bool isProvider;
  final VoidCallback onPaymentComplete;

  const PaymentMethodSheet({
    super.key,
    required this.bookingId,
    required this.invoice,
    required this.isProvider,
    required this.onPaymentComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required Map<String, dynamic> invoice,
    required bool isProvider,
    required VoidCallback onPaymentComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSheet(
        bookingId: bookingId,
        invoice: invoice,
        isProvider: isProvider,
        onPaymentComplete: onPaymentComplete,
      ),
    );
  }

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  final PaymentDataSource _paymentDataSource = PaymentDataSource();
  bool _isLoading = false;
  String? _selectedMethod; // 'cod' or 'momo'
  String? _momoPayUrl;
  String? _momoDeeplink;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get pricing => widget.invoice['pricing'] ?? {};

  double get totalAmount => (pricing['totalAmount'] ?? 0).toDouble();
  double get platformFee => (pricing['platformFee'] ?? 0).toDouble();
  double get actualPrice =>
      (pricing['actualPrice'] ?? pricing['estimatedPrice'] ?? 0).toDouble();

  Future<void> _handleCodPayment() async {
    if (widget.isProvider) {
      // Provider confirms receiving cash
      setState(() => _isLoading = true);
      try {
        await _paymentDataSource.confirmBookingCod(widget.bookingId);
        if (mounted) {
          Navigator.pop(context);
          widget.onPaymentComplete();
          _showSuccessDialog('Đã xác nhận nhận tiền mặt!');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Customer selects COD - just show instructions
      setState(() => _selectedMethod = 'cod');
    }
  }

  Future<void> _handleMomoPayment() async {
    setState(() {
      _isLoading = true;
      _selectedMethod = 'momo';
    });

    try {
      final response = await _paymentDataSource.payWithMomo(widget.bookingId);
      final payUrl = response['payUrl'] as String?;
      final deeplink = response['deeplink'] as String?;
      final orderId = response['orderId'] as String?;

      if (payUrl != null) {
        setState(() {
          _momoPayUrl = payUrl;
          _momoDeeplink = deeplink;
        });

        // Start polling for payment status
        if (orderId != null) {
          _startPolling(orderId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _selectedMethod = null);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling(String orderId) {
    _pollingTimer?.cancel();
    int attempts = 0;
    const maxAttempts = 40; // 2 minutes

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > maxAttempts) {
        timer.cancel();
        return;
      }

      try {
        // Check booking status instead of payment status
        // The booking should move to 'completed' after successful MoMo payment
        final result = await _paymentDataSource.checkDepositStatus(orderId);
        final status = result['status'] as String?;

        if (status == 'success') {
          timer.cancel();
          if (mounted) {
            Navigator.pop(context);
            widget.onPaymentComplete();
            _showSuccessDialog('Thanh toán thành công!');
          }
        }
      } catch (e) {
        debugPrint('[PaymentSheet] Polling error: $e');
      }
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 80),
            const SizedBox(height: 24),
            Text(message,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.isProvider ? 'Xác nhận thanh toán' : 'Thanh toán dịch vụ',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Invoice Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInvoiceRow(
                      'Dịch vụ', widget.invoice['service']?['name'] ?? 'N/A'),
                  const Divider(height: 24),
                  _buildInvoiceRow(
                      'Giá dịch vụ', currencyFormat.format(actualPrice)),
                  if (platformFee > 0) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow('Phí nền tảng (10%)',
                        currencyFormat.format(platformFee),
                        isSubtle: true),
                  ],
                  const Divider(height: 24),
                  _buildInvoiceRow(
                    'Tổng cộng',
                    currencyFormat.format(totalAmount),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods or QR Code
            if (_momoPayUrl != null) ...[
              _buildMomoQRSection(),
            ] else if (_selectedMethod == 'cod' && !widget.isProvider) ...[
              _buildCodInstructions(),
            ] else ...[
              _buildPaymentMethodSelection(),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value,
      {bool isBold = false, bool isSubtle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubtle ? 14 : 16,
            color: isSubtle ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // COD Option
        _buildPaymentOption(
          icon: Icons.payments_outlined,
          title: 'Tiền mặt (COD)',
          subtitle: widget.isProvider
              ? 'Xác nhận đã nhận tiền từ khách'
              : 'Thanh toán trực tiếp cho thợ',
          onTap: _isLoading ? null : _handleCodPayment,
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        // MoMo Option (only for customer)
        if (!widget.isProvider)
          _buildPaymentOption(
            icon: Icons.qr_code_rounded,
            title: 'Ví MoMo',
            subtitle: 'Quét mã QR để thanh toán',
            onTap: _isLoading ? null : _handleMomoPayment,
            color: Colors.pink,
          ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCodInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Thanh toán tiền mặt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng thanh toán ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalAmount)} trực tiếp cho thợ.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sau khi thanh toán, thợ sẽ xác nhận đã nhận tiền và đơn hàng sẽ hoàn tất.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _selectedMethod = null),
            child: const Text('← Chọn phương thức khác'),
          ),
        ],
      ),
    );
  }

  Widget _buildMomoQRSection() {
    return Column(
      children: [
        const Text(
          'Quét mã để thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: QrImageView(
            data: _momoPayUrl!,
            version: QrVersions.auto,
            size: 200.0,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.primaryDark,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _momoPayUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép liên kết')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Sao chép'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_momoDeeplink ?? _momoPayUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: const Text('Mở MoMo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Đang chờ thanh toán...',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _pollingTimer?.cancel();
            setState(() {
              _selectedMethod = null;
              _momoPayUrl = null;
            });
          },
          child: const Text('← Chọn phương thức khác'),
        ),
      ],
    );
  }
}
