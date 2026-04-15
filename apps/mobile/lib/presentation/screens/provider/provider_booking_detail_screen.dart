import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../../core/constants/app_constants.dart';

class ProviderBookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const ProviderBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<ProviderBookingDetailScreen> createState() => _ProviderBookingDetailScreenState();
}

class _ProviderBookingDetailScreenState extends State<ProviderBookingDetailScreen> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    // Using colors from Figma design
    const Color figmaBgColor = Color(0xFFF3FCEF);
    const Color figmaPrimaryGreen = Color(0xFF00B64F);
    const Color figmaTextPrimary = Color(0xFF161D16);
    const Color figmaTextSecondary = Color(0xFF3D4A3D);
    const Color figmaAiSectionBg = Color(0xFF155125);

    return Scaffold(
      backgroundColor: figmaBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.6),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: figmaTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Chi tiết dịch vụ',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.45,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: figmaPrimaryGreen),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<BookingsBloc, BookingsState>(
        builder: (context, state) {
          Booking booking = widget.booking;
          if (state is BookingsLoaded) {
            try {
              booking = state.bookings.firstWhere((b) => b.id == widget.booking.id);
            } catch (_) {}
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Identity Header
                Text(
                  'MÃ ĐƠN HÀNG: #${booking.code}'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: figmaPrimaryGreen.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: figmaTextPrimary,
                    letterSpacing: -0.75,
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Info Card
                _buildPrimaryInfoCard(booking, currencyFormat, dateFormat, figmaPrimaryGreen, figmaTextPrimary, figmaTextSecondary),
                const SizedBox(height: 32),

                // Visual Context Section (Current State Images)
                _buildVisualContextSection(booking, figmaTextPrimary),
                const SizedBox(height: 32),

                // AI Call to Action Section
                _buildAiSection(booking, figmaAiSectionBg, figmaPrimaryGreen),
                const SizedBox(height: 40),

                // Original Action Buttons (Compatibility with existing flow)
                _buildOriginalActions(booking),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimaryInfoCard(
    Booking booking,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    Color primaryGreen,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBCCBB9).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName ?? 'Dịch vụ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(booking.status, primaryGreen),
                  ],
                ),
              ),
              if (booking.distance != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Khoảng cách',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      booking.distance! < 1000 
                          ? '${booking.distance} m' 
                          : '${(booking.distance! / 1000).toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Detail Info Rows
          _buildInfoRow(Icons.person_rounded, 'KHÁCH HÀNG', booking.customerName ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_rounded, 'ĐỊA CHỈ', booking.addressText ?? 'N/A', textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_filled_rounded, 
            'THỜI GIAN HẸN', 
            booking.scheduledAt != null ? dateFormat.format(booking.scheduledAt!) : 'N/A', 
            textPrimary, 
            textSecondary
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color primaryGreen) {
    String label = status.toUpperCase();
    Color color = primaryGreen;

    switch (status) {
      case 'in_progress':
        label = 'Đang thực hiện';
        color = primaryGreen;
        break;
      case 'pending':
        label = 'Đang chờ';
        color = Colors.orange;
        break;
      case 'completed':
        label = 'Hoàn thành';
        color = Colors.blue;
        break;
      case 'accepted':
      case 'confirmed':
        label = 'Đã nhận';
        color = primaryGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary.withOpacity(0.6),
                    letterSpacing: 0.55,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualContextSection(Booking booking, Color textPrimary) {
    final images = booking.customerImages ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HÌNH ẢNH HIỆN TRẠNG',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        if (images.isNotEmpty)
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildImageCard(images[index]);
              },
            ),
          )
        else
          _buildImagePlaceholder(),
      ],
    );
  }

  Widget _buildImageCard(String imageUrl) {
    final fullUrl = imageUrl.startsWith('http') 
        ? imageUrl 
        : '${AppConstants.apiBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';

    return Container(
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(fullUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'ẢNH TẢI LÊN BỞI KHÁCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'Khách hàng không tải lên hình ảnh',
            style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection(Booking booking, Color bgColor, Color primaryGreen) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trợ lý AI ServiceHub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phân tích hình ảnh để dự đoán lỗi và gợi ý\nlinh kiện thay thế ngay lập tức.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD1FAE5).withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          MinButton(
            text: 'Chẩn đoán hư hỏng',
            isFullWidth: true,
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            icon: Icons.auto_awesome_rounded,
            onPressed: () {
              _showAiDiagnosisDialog(booking);
            },
          ),
        ],
      ),
    );
  }

  void _showAiDiagnosisDialog(Booking booking) {
    context.push('/booking/ai-diagnosis/${booking.id}', extra: booking);
  }

  Widget _buildOriginalActions(Booking booking) {
    // Reusing logic from BookingDetailScreen for consistency
    final status = booking.status;
    final id = booking.id;

    if (status == 'accepted' || status == 'confirmed') {
      return MinButton(
        text: 'Bắt đầu dịch vụ',
        isFullWidth: true,
        isLoading: _isActionLoading,
        onPressed: () => context.read<BookingsBloc>().add(StartService(id)),
        icon: Icons.play_arrow_rounded,
      );
    }
    
    if (status == 'in_progress') {
      return Column(
        children: [
          MinButton(
            text: 'Hoàn thành việc',
            isFullWidth: true,
            isLoading: _isActionLoading,
            onPressed: () => context.read<BookingsBloc>().add(CompleteService(id)),
            icon: Icons.check_circle_rounded,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
