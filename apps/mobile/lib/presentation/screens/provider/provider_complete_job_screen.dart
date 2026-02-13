import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/payment_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/payment_datasource.dart';

/// Screen for provider to complete service job
/// Provider can update final price, add additional costs, and confirm completion
class ProviderCompleteJobScreen extends StatefulWidget {
  final String bookingId;

  const ProviderCompleteJobScreen({super.key, required this.bookingId});

  @override
  State<ProviderCompleteJobScreen> createState() =>
      _ProviderCompleteJobScreenState();
}

class _ProviderCompleteJobScreenState extends State<ProviderCompleteJobScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final _formKey = GlobalKey<FormState>();

  final _actualPriceController = TextEditingController();
  final _additionalCostsController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  Map<String, dynamic>? _invoice;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  bool _hasAdditionalCosts = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  @override
  void dispose() {
    _actualPriceController.dispose();
    _additionalCostsController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
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

        // Pre-fill with estimated price
        final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
        final estimatedPrice = (pricing['estimatedPrice'] ?? 0).toDouble();
        _actualPriceController.text = estimatedPrice.toStringAsFixed(0);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePriceAndComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final actualPrice =
          double.parse(_actualPriceController.text.replaceAll(',', ''));
      double? additionalCosts;
      String? additionalNotes;

      if (_hasAdditionalCosts && _additionalCostsController.text.isNotEmpty) {
        additionalCosts =
            double.parse(_additionalCostsController.text.replaceAll(',', ''));
        additionalNotes = _additionalNotesController.text.isNotEmpty
            ? _additionalNotesController.text
            : null;
      }

      // Update price
      await _paymentRepository.updateFinalPrice(
        bookingId: widget.bookingId,
        actualPrice: actualPrice,
        additionalCosts: additionalCosts,
        additionalNotes: additionalNotes,
      );

      // Mark as complete
      await _paymentRepository.markServiceComplete(widget.bookingId);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmCodPayment() async {
    setState(() => _isProcessing = true);

    try {
      await _paymentRepository.confirmBookingCod(widget.bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận thanh toán thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành dịch vụ!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang chờ khách hàng thanh toán',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Hoàn thành dịch vụ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Không thể tải thông tin',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadInvoice, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_invoice == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final status = _invoice!['status'] as String? ?? '';
    final paymentStatus = _invoice!['paymentStatus'] as String? ?? '';
    final paymentMethod = _invoice!['paymentMethod'] as String? ?? '';
    final isPendingPayment = status == 'pending_payment';
    final isCod = paymentMethod.toUpperCase() == 'COD';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status info
            _buildStatusCard(status, paymentStatus),
            const SizedBox(height: 20),

            // If already pending_payment for COD, show confirm button
            if (isPendingPayment && isCod) ...[
              _buildConfirmCodSection(),
            ] else if (!isPendingPayment) ...[
              // Price update form
              _buildPriceSection(),
              const SizedBox(height: 16),

              // Additional costs
              _buildAdditionalCostsSection(),
              const SizedBox(height: 24),

              // Price preview
              _buildPricePreview(),
              const SizedBox(height: 24),

              // Complete button
              _buildCompleteButton(),
            ] else ...[
              _buildWaitingForPayment(),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String paymentStatus) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;
    String description;

    if (paymentStatus == 'paid') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
      text = 'Đã hoàn thành';
      description = 'Khách hàng đã thanh toán';
    } else if (status == 'pending_payment') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.pending;
      text = 'Chờ thanh toán';
      description = 'Đang chờ khách hàng thanh toán';
    } else if (status == 'in_progress') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.build;
      text = 'Đang thực hiện';
      description = 'Cập nhật giá và hoàn thành khi xong';
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.info;
      text = status;
      description = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                        color: textColor.withOpacity(0.8), fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Text(
                'Giá dịch vụ thực tế',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _actualPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Giá thực tế (VNĐ)',
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập giá';
              final price = double.tryParse(value.replaceAll(',', ''));
              if (price == null || price <= 0) return 'Giá không hợp lệ';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCostsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Chi phí phát sinh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Switch(
                value: _hasAdditionalCosts,
                onChanged: (v) => setState(() => _hasAdditionalCosts = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_hasAdditionalCosts) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _additionalCostsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền phát sinh (VNĐ)',
                prefixIcon: const Icon(Icons.add),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _additionalNotesController,
              decoration: InputDecoration(
                labelText: 'Lý do phát sinh (tùy chọn)',
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricePreview() {
    final actualPrice =
        double.tryParse(_actualPriceController.text.replaceAll(',', '')) ?? 0;
    final additionalCosts = _hasAdditionalCosts
        ? (double.tryParse(
                _additionalCostsController.text.replaceAll(',', '')) ??
            0)
        : 0.0;
    final total = actualPrice + additionalCosts;
    final platformFee = total * 0.10;
    final providerEarning = total - platformFee;

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryLight.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giá dịch vụ'),
              Text(formatter.format(actualPrice),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          if (additionalCosts > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phát sinh',
                    style: TextStyle(color: Colors.orange.shade700)),
                Text(formatter.format(additionalCosts),
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí platform (10%)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('-${formatter.format(platformFee)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bạn nhận được',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                formatter.format(providerEarning),
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _updatePriceAndComplete,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle),
        label: Text(_isProcessing ? 'Đang xử lý...' : 'Hoàn thành dịch vụ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildConfirmCodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.payments, color: Colors.green.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            'Xác nhận đã nhận tiền mặt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sau khi nhận đủ tiền từ khách hàng, nhấn nút bên dưới để hoàn tất.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirmCodPayment,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(
                  _isProcessing ? 'Đang xác nhận...' : 'Xác nhận đã nhận tiền'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForPayment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.access_time, color: Colors.blue.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            'Đang chờ thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khách hàng đang thanh toán qua MoMo.\nVui lòng chờ xác nhận.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
