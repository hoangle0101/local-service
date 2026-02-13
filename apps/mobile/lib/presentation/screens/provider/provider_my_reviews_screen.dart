import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/reviews_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../widgets/review/review_card.dart';
import '../../widgets/rating/star_rating.dart';

/// Beautiful "My Reviews" screen for providers to see customer feedback
class ProviderMyReviewsScreen extends StatefulWidget {
  const ProviderMyReviewsScreen({super.key});

  @override
  State<ProviderMyReviewsScreen> createState() =>
      _ProviderMyReviewsScreenState();
}

class _ProviderMyReviewsScreenState extends State<ProviderMyReviewsScreen> {
  final ReviewsDataSource _dataSource = ReviewsDataSource();
  final ScrollController _scrollController = ScrollController();

  List<ReviewModel> _reviews = [];
  Map<int, int> _distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalReviews = 0;
  double _averageRating = 0;
  String? _error;
  String? _providerId;

  @override
  void initState() {
    super.initState();
    _getProviderId();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _getProviderId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.user != null) {
      _providerId = authState.user!.id;
      _loadReviews();
    } else {
      setState(() {
        _error = 'Vui lòng đăng nhập lại';
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (_providerId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _dataSource.getProviderReviews(
        _providerId!,
        page: 1,
        limit: 20,
      );

      final reviews = result['reviews'] as List<ReviewModel>;
      final meta = result['meta'] as Map<String, dynamic>;

      // Calculate distribution and average
      final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRating = 0;
      for (final review in reviews) {
        final rating = review.rating.clamp(1, 5);
        dist[rating] = (dist[rating] ?? 0) + 1;
        totalRating += rating;
      }

      setState(() {
        _reviews = reviews;
        _distribution = dist;
        _totalReviews = meta['total'] ?? reviews.length;
        _averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0;
        _currentPage = 1;
        _hasMore = _currentPage < (meta['totalPages'] ?? 1);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMore || _providerId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _dataSource.getProviderReviews(
        _providerId!,
        page: _currentPage + 1,
        limit: 20,
      );

      final reviews = result['reviews'] as List<ReviewModel>;
      final meta = result['meta'] as Map<String, dynamic>;

      setState(() {
        _reviews.addAll(reviews);
        _currentPage++;
        _hasMore = _currentPage < (meta['totalPages'] ?? 1);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState()
            else ...[
              _buildReviewsList(),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Đánh giá của tôi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Stats section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Big rating
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  _averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StarRating(
                                  rating: _averageRating,
                                  size: 20,
                                  alignment: MainAxisAlignment.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$_totalReviews đánh giá',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 100,
                            color: AppColors.borderLight,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),

                          // Distribution
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [5, 4, 3, 2, 1].map((stars) {
                                final count = _distribution[stars] ?? 0;
                                final total =
                                    _reviews.isNotEmpty ? _reviews.length : 1;
                                final percentage = count / total;
                                return _buildDistributionRow(
                                    stars, percentage, count);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionRow(int stars, double percentage, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$stars',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0, 1),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không thể tải đánh giá',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phản hồi từ khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalReviews',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_reviews.isEmpty)
              _buildEmptyState()
            else
              ..._reviews.map((review) => ReviewCard(review: review)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành công việc để nhận đánh giá\ntừ khách hàng của bạn!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
