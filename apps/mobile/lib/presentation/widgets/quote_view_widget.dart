import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/quote_datasource.dart';
import 'minimalist_widgets.dart';

class QuoteViewWidget extends StatefulWidget {
  final String bookingId;
  final VoidCallback? onQuoteAccepted;
  final VoidCallback? onQuoteRejected;

  const QuoteViewWidget({
    super.key,
    required this.bookingId,
    this.onQuoteAccepted,
    this.onQuoteRejected,
  });

  @override
  State<QuoteViewWidget> createState() => _QuoteViewWidgetState();
}

class _QuoteViewWidgetState extends State<QuoteViewWidget> {
  final QuoteDataSource _quoteDataSource = QuoteDataSource();
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    debugPrint('[QuoteView] Loading quotes for booking: ${widget.bookingId}');
    try {
      final quotes =
          await _quoteDataSource.getQuotesForBooking(widget.bookingId);
      debugPrint('[QuoteView] Loaded ${quotes.length} quotes: $quotes');
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[QuoteView] Error loading quotes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptQuote(String quoteId) async {
    setState(() => _isActionLoading = true);
    try {
      await _quoteDataSource.acceptQuote(quoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận báo giá! Thợ sẽ tiến hành sửa chữa.'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onQuoteAccepted?.call();
        _loadQuotes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _showRejectDialog(String quoteId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối báo giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do từ chối:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Vd: Giá quá cao...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      await _rejectQuote(quoteId, reasonController.text);
    }
  }

  Future<void> _rejectQuote(String quoteId, String reason) async {
    setState(() => _isActionLoading = true);
    try {
      await _quoteDataSource.rejectQuote(quoteId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối báo giá.'),
            backgroundColor: AppColors.warning,
          ),
        );
        widget.onQuoteRejected?.call();
        _loadQuotes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    final value =
        amount is int ? amount.toDouble() : (amount as num).toDouble();
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
        .format(value)
        .replaceAll(',00', '');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 60, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Chưa có báo giá',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thợ chưa gửi báo giá cho đơn này',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    final pendingQuotes =
        _quotes.where((q) => q['status'] == 'pending').toList();
    final acceptedQuotes =
        _quotes.where((q) => q['status'] == 'accepted').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingQuotes.isNotEmpty) ...[
          _buildSectionTitle('Báo giá chờ duyệt', Icons.receipt_long_rounded),
          const SizedBox(height: 12),
          ...pendingQuotes.map((q) => _buildQuoteCard(q, isPending: true)),
        ],
        if (acceptedQuotes.isNotEmpty) ...[
          _buildSectionTitle(
              'Báo giá đã chấp nhận', Icons.check_circle_rounded),
          const SizedBox(height: 12),
          ...acceptedQuotes.map((q) => _buildQuoteCard(q, isPending: false)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote,
      {required bool isPending}) {
    final items = (quote['items'] as List?) ?? [];
    final providerName = quote['provider']?['fullName'] ?? 'Thợ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withOpacity(0.5)
              : AppColors.success.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      providerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPending ? 'Chờ duyệt' : 'Đã chấp nhận',
                  style: TextStyle(
                    color: isPending ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Diagnosis
          Text(
            'Chẩn đoán:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote['diagnosis'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // Items
          Text(
            'Chi tiết dịch vụ:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item['name']} x${item['quantity']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _formatCurrency(item['price'] * item['quantity']),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),

          // Labor cost
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('• Công sửa chữa', style: TextStyle(fontSize: 14)),
                Text(
                  _formatCurrency(quote['laborCost'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng (đã gồm phí nền tảng):',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                _formatCurrency(quote['finalPrice'] ?? 0),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Warranty
          if (quote['warranty'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Bảo hành: ${quote['warranty']}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // Actions for pending quotes
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MinButton(
                    text: 'Từ chối',
                    isPrimary: false,
                    isFullWidth: true,
                    onPressed: _isActionLoading
                        ? null
                        : () => _showRejectDialog(quote['id']),
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MinButton(
                    text: 'Chấp nhận',
                    isFullWidth: true,
                    isLoading: _isActionLoading,
                    onPressed: _isActionLoading
                        ? null
                        : () => _acceptQuote(quote['id']),
                    icon: Icons.check_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
