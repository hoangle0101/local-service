import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/entities/entities.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../reviews/provider_reviews_screen.dart';
import 'package:dio/dio.dart';
import '../../../data/storage/secure_storage.dart';
import '../../bloc/favorites/favorites_bloc.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/minimalist_widgets.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  final ProviderService? service;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    this.service,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late ServicesBloc _servicesBloc;
  ProviderService? _service;
  List<Map<String, dynamic>> _serviceItems = [];
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _servicesBloc = ServicesBloc();

    if (_service == null) {
      _servicesBloc.add(LoadServiceDetails(widget.serviceId));
    } else {
      _loadServiceItems(_service!);
    }
  }

  Future<void> _loadServiceItems(ProviderService service) async {
    setState(() => _loadingItems = true);
    try {
      final url =
          '/services/${service.serviceId}/provider/${service.providerUserId}/items';
      print('[ServiceDetails] Loading items from: $url');
      print(
          '[ServiceDetails] serviceId: ${service.serviceId}, providerUserId: ${service.providerUserId}');

      final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));
      final token = await SecureStorage.getAccessToken();
      final response = await dio.get(
        url,
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      print('[ServiceDetails] Response status: ${response.statusCode}');
      print('[ServiceDetails] Response data: ${response.data}');
      print(
          '[ServiceDetails] Response data type: ${response.data.runtimeType}');

      if (mounted) {
        // Handle both direct array and wrapped response {statusCode, message, data: [...]}
        List<dynamic> rawItems;
        if (response.data is List) {
          rawItems = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          rawItems = response.data['data'];
        } else {
          rawItems = [];
        }

        final items = List<Map<String, dynamic>>.from(rawItems);
        print('[ServiceDetails] Parsed ${items.length} items');
        setState(() {
          _serviceItems = items;
          _loadingItems = false;
        });
      }
    } catch (e, stack) {
      print('[ServiceDetails] ERROR loading items: $e');
      print('[ServiceDetails] Stack: $stack');
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  @override
  void dispose() {
    _servicesBloc.close();
    super.dispose();
  }

  /// Parse price from dynamic (could be string or num) to num
  num _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is num) return price;
    if (price is String) return num.tryParse(price) ?? 0;
    return 0;
  }

  void _openProviderReviews(BuildContext context, ProviderService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderReviewsScreen(
          providerId: service.providerUserId,
          providerName: service.provider.displayName,
          providerAvatarUrl: service.provider.avatarUrl,
          ratingAvg: service.provider.ratingAvg,
          ratingCount: service.provider.ratingCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_service != null) {
      return _buildContent(_service!);
    }

    return BlocProvider.value(
      value: _servicesBloc,
      child: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            );
          } else if (state is ServiceDetailsLoaded) {
            _service = state.service;
            // Load items if not already loading
            if (!_loadingItems && _serviceItems.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadServiceItems(state.service);
              });
            }
            return _buildContent(state.service);
          } else if (state is ServicesError) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Lỗi: ${state.message}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    MinButton(
                      text: 'Thử lại',
                      onPressed: () => _servicesBloc
                          .add(LoadServiceDetails(widget.serviceId)),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        },
      ),
    );
  }

  Widget _buildContent(ProviderService service) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, service),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, service, currencyFormat),
                  const SizedBox(height: 32),
                  _buildSectionLabel('DỊCH VỤ ĐƯỢC CUNG CẤP BỞI'),
                  const SizedBox(height: 16),
                  _buildProviderInfo(context, service),
                  const SizedBox(height: 32),
                  _buildSectionLabel('BẢNG GIÁ THAM KHẢO'),
                  const SizedBox(height: 16),
                  _buildServiceItems(service),
                  const SizedBox(height: 32),
                  _buildSectionLabel('MÔ TẢ CHI TIẾT'),
                  const SizedBox(height: 16),
                  _buildDescription(context, service),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, service, currencyFormat),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProviderService service) {
    return SliverAppBar(
      expandedHeight: 350.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildServiceImage(),
            // Gradient overlays for premium look
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${service.provider.ratingAvg}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${service.provider.ratingCount})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 70,
      leading: Center(
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, state) {
                  final isFavorite = state.favoriteIds.contains(service.id);
                  return FavoriteButton(
                    isFavorite: isFavorite,
                    size: 18,
                    padding: EdgeInsets.zero,
                    unfavoriteColor: AppColors.textPrimary,
                    onToggle: () {
                      context
                          .read<FavoritesBloc>()
                          .add(ToggleFavorite(service.id));
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? 'Đã xóa "${service.service.name}" khỏi yêu thích'
                                : 'Đã thêm "${service.service.name}" vào yêu thích',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.all(24),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceImage() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.shelf,
      ),
      child: const Center(
        child: Icon(Icons.home_repair_service_rounded,
            size: 80, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProviderService service,
      NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                service.service.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${service.service.durationMinutes ?? 60} p',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Show "Contact for quote" instead of fixed price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.request_quote_rounded,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Liên hệ báo giá',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(BuildContext context, ProviderService service) {
    return MinCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                service.provider.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        service.provider.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (service.provider.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openProviderReviews(context, service),
                  child: Row(
                    children: [
                      const Text(
                        'Xem tất cả đánh giá',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {}, // Future chat implementation
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.shelf.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, ProviderService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Text(
        service.service.description ??
            'Thông tin chi tiết về dịch vụ này hiện đang được cập nhật bởi nhà cung cấp.',
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.7,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildServiceItems(ProviderService service) {
    if (_loadingItems) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_serviceItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 32, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'Chưa có bảng giá',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Thợ sẽ báo giá sau khi kiểm tra',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        children: _serviceItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == _serviceItems.length - 1;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: AppColors.divider.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                // Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.shelf,
                    borderRadius: BorderRadius.circular(10),
                    image: item['imageUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(item['imageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item['imageUrl'] == null
                      ? const Icon(Icons.build_rounded,
                          size: 20, color: AppColors.textTertiary)
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (item['description'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Price
                Text(
                  currencyFormat
                      .format(_parsePrice(item['price']))
                      .replaceAll(',00', ''),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProviderService service,
      NumberFormat currencyFormat) {
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is Authenticated && authState.user != null) {
      currentUserId = authState.user!.id;
    }

    final isOwnService =
        currentUserId != null && service.providerUserId == currentUserId;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GIÁ DỊCH VỤ',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Liên hệ báo giá',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: isOwnService
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.shelf.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Center(
                        child: Text(
                          'DỊCH VỤ CỦA BẠN',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  : MinButton(
                      text: 'Đặt lịch ngay',
                      onPressed: () {
                        context.push(
                          '/booking/create',
                          extra: {
                            'serviceId': service.serviceId,
                            'service': service,
                            'providerId': int.tryParse(service.providerUserId),
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
