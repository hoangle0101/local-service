import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class BookingDisputeScreen extends StatefulWidget {
  final String bookingId;

  const BookingDisputeScreen({super.key, required this.bookingId});

  @override
  State<BookingDisputeScreen> createState() => _BookingDisputeScreenState();
}

class _BookingDisputeScreenState extends State<BookingDisputeScreen> {
  final _reasonController = TextEditingController();
  final _bookingsDataSource = BookingsDataSource();
  bool _isLoading = false;

  Future<void> _submitDispute() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do khiếu nại')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _bookingsDataSource.disputeBooking(
        widget.bookingId,
        _reasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Đã gửi khiếu nại thành công. Chúng tôi sẽ xem xét sớm nhất.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<BookingsBloc>().add(const LoadBookings());
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Khiếu nại / Báo cáo sự cố',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chúng tôi rất tiếc vì sự cố bạn gặp phải.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng mô tả chi tiết sự cố hoặc lý do bạn muốn khiếu nại. Đội ngũ hỗ trợ sẽ liên hệ với bạn trong vòng 24h.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Lý do khiếu nại',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                    'VD: Thợ làm không đúng cam kết, Thợ đòi thêm tiền ngoài báo giá...',
                fillColor: AppColors.shelf.withOpacity(0.3),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 48),
            MinButton(
              text: 'GỬI KHIẾU NẠI',
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _submitDispute,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
