import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/payment_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/payment_datasource.dart';
import '../../widgets/minimalist_widgets.dart';

class InvoiceScreen extends StatefulWidget {
  final String bookingId;

  const InvoiceScreen({super.key, required this.bookingId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();

  Map<String, dynamic>? _invoice;
  bool _isLoading = true;

  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invoice = await _paymentRepository.getInvoice(widget.bookingId);
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _payWithMomo() async {
    if (_invoice == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _paymentRepository.payWithMomo(widget.bookingId);
      final payUrl = result['payUrl'] as String?;
      final deeplink = result['deeplink'] as String?;

      if (deeplink != null && deeplink.isNotEmpty) {
        final uri = Uri.parse(deeplink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (payUrl != null) {
          await launchUrl(Uri.parse(payUrl),
              mode: LaunchMode.externalApplication);
        }
      } else if (payUrl != null) {
        await launchUrl(Uri.parse(payUrl),
            mode: LaunchMode.externalApplication);
      }

      await Future.delayed(const Duration(seconds: 2));
      _loadInvoice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hóa đơn dịch vụ',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Không thể tải hóa đơn',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              MinButton(
                text: 'Thử lại',
                onPressed: _loadInvoice,
              ),
            ],
          ),
        ),
      );
    }

    if (_invoice == null) {
      return const Center(
          child: Text('Không có dữ liệu',
              style: TextStyle(fontWeight: FontWeight.w700)));
    }

    final pricing = _invoice!['pricing'] as Map<String, dynamic>? ?? {};
    final service = _invoice!['service'] as Map<String, dynamic>? ?? {};
    final provider = _invoice!['provider'] as Map<String, dynamic>? ?? {};
    final status = _invoice!['status'] as String? ?? '';
    final paymentStatus = _invoice!['paymentStatus'] as String? ?? '';
    final paymentMethod = _invoice!['paymentMethod'] as String? ?? '';

    final estimatedPrice = (pricing['estimatedPrice'] ?? 0).toDouble();
    final actualPrice = (pricing['actualPrice'] ?? 0).toDouble();
    final additionalCosts = (pricing['additionalCosts'] ?? 0).toDouble();
    final platformFee = (pricing['platformFee'] ?? 0).toDouble();
    final totalAmount = (pricing['totalAmount'] ?? 0).toDouble();

    final isPaid = paymentStatus == 'paid';
    final isPendingPayment = status == 'pending_payment';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(status, paymentStatus),
          const SizedBox(height: 32),
          _buildSectionLabel('THÔNG TIN ĐƠN HÀNG'),
          const SizedBox(height: 12),
          MinCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                    'Mã Booking', '#${_invoice!['bookingCode'] ?? 'N/A'}',
                    isCode: true),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1)),
                _buildInfoRow('Dịch vụ', service['name'] ?? 'Dịch vụ lẻ'),
                const SizedBox(height: 12),
                _buildInfoRow('Nhà cung cấp', provider['name'] ?? 'Tự do'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionLabel('CHI TIẾT THANH TOÁN'),
          const SizedBox(height: 12),
          _buildPricingSection(
            estimatedPrice: estimatedPrice,
            actualPrice: actualPrice,
            additionalCosts: additionalCosts,
            additionalNotes: pricing['additionalNotes'] as String?,
            platformFee: platformFee,
            totalAmount: totalAmount,
          ),
          const SizedBox(height: 32),
          _buildSectionLabel('PHƯƠNG THỨC'),
          const SizedBox(height: 12),
          _buildPaymentMethodCard(paymentMethod),
          const SizedBox(height: 48),
          if (isPendingPayment && !isPaid) ...[
            if (paymentMethod.toLowerCase() == 'momo')
              _buildMomoPayButton()
            else
              _buildCodInfo(),
          ] else if (isPaid) ...[
            _buildPaidSuccess(),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatusBanner(String status, String paymentStatus) {
    Color color;
    IconData icon;
    String text;
    String subText;

    if (paymentStatus == 'paid') {
      color = AppColors.success;
      icon = Icons.verified_rounded;
      text = 'Đã thanh toán';
      subText = 'Giao dịch đã được xác nhận hoàn tất';
    } else if (status == 'pending_payment') {
      color = AppColors.warning;
      icon = Icons.pending_rounded;
      text = 'Chờ thanh toán';
      subText = 'Vui lòng hoàn tất thanh toán để kết thúc đơn...';
    } else {
      color = AppColors.primary;
      icon = Icons.info_rounded;
      text = 'Đang xử lý';
      subText = 'Trạng thái đơn hàng đang được cập nhật...';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isCode ? AppColors.primary : AppColors.textPrimary,
              letterSpacing: isCode ? 1.0 : 0,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection({
    required double estimatedPrice,
    required double actualPrice,
    required double additionalCosts,
    String? additionalNotes,
    required double platformFee,
    required double totalAmount,
  }) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (actualPrice > 0) ...[
            _buildPriceRow('Giá dịch vụ thực tế', actualPrice),
          ] else ...[
            _buildPriceRow('Giá dịch vụ ước tính', estimatedPrice),
          ],
          const SizedBox(height: 16),
          if (additionalCosts > 0) ...[
            _buildPriceRow('Chi phí phát sinh', additionalCosts,
                color: Colors.orange),
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text('Note: $additionalNotes',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic)),
                ),
              ),
            const SizedBox(height: 16),
          ],
          _buildPriceRow('Phí nền tảng (10%)', platformFee, isSubtle: true),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TỔNG THANH TOÁN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(
                formatter.format(totalAmount),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isSubtle = false, Color? color}) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color:
                  isSubtle ? AppColors.textTertiary : AppColors.textSecondary,
              fontSize: isSubtle ? 13 : 14,
              fontWeight: isSubtle ? FontWeight.w600 : FontWeight.w700,
            )),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color ??
                (isSubtle ? AppColors.textTertiary : AppColors.textPrimary),
            fontWeight: FontWeight.w900,
            fontSize: isSubtle ? 13 : 15,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    final isMomo = method.toLowerCase() == 'momo';

    return MinCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMomo
                  ? const Color(0xFFAE2070).withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMomo ? Icons.phone_android_rounded : Icons.payments_rounded,
              color: isMomo ? const Color(0xFFAE2070) : AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PHƯƠNG THỨC',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  isMomo ? 'Ví MoMo' : 'Tiền mặt (COD)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomoPayButton() {
    return MinButton(
      text: _isProcessing ? 'ĐANG XỬ LÝ...' : 'THANH TOÁN QUA MOMO',
      onPressed: _isProcessing ? null : _payWithMomo,
      backgroundColor: const Color(0xFFAE2070),
      isLoading: _isProcessing,
    );
  }

  Widget _buildCodInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.success, size: 32),
          const SizedBox(height: 12),
          const Text('Thanh toán tiền mặt',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                  fontSize: 17)),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng thanh toán trực tiếp cho nhà cung cấp.\nHọ sẽ xác nhận hoàn tất sau khi nhận tiền.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidSuccess() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text('Đã nhận thanh toán',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.success)),
              const SizedBox(height: 8),
              const Text('Cảm ơn bạn đã tin dùng dịch vụ của chúng tôi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        MinButton(
          text: 'VỀ LỊCH ĐẶT CỦA TÔI',
          onPressed: () => context.go('/user/bookings'),
        ),
      ],
    );
  }
}
