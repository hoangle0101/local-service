import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'rating/star_rating.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import 'favorite_button.dart';
import 'minimalist_widgets.dart';

/// Modern card for displaying a favorite service item
/// Features swipe-to-delete and tap to navigate
class FavoriteServiceCard extends StatelessWidget {
  final FavoriteItem favorite;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const FavoriteServiceCard({
    super.key,
    required this.favorite,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(favorite.serviceId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showConfirmDialog(context);
      },
      onDismissed: (_) => onRemove?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/service/${favorite.serviceId}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Icon
                  _buildServiceIcon(),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service name
                        Text(
                          favorite.service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Provider info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                favorite.provider.displayName.isNotEmpty
                                    ? favorite.provider.displayName[0]
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                favorite.provider.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (favorite.provider.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rating and Price row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rating
                            Row(
                              children: [
                                StarRating(
                                  rating: favorite.provider.ratingAvg,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${favorite.provider.ratingCount})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            // Price
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_formatPrice(favorite.price)} ${favorite.currency}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Category tag
                        if (favorite.service.category != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              favorite.service.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Remove button
                  if (showRemoveButton)
                    FavoriteButton(
                      isFavorite: true,
                      onToggle: onRemove,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.home_repair_service,
        size: 32,
        color: AppColors.primaryDark,
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    final result = await MinDialog.show<bool>(
      context: context,
      title: 'Xóa khỏi yêu thích?',
      message:
          'Bạn có chắc muốn xóa "${favorite.service.name}" khỏi danh sách yêu thích?',
      primaryLabel: 'Xóa',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      secondaryLabel: 'Hủy',
      onPrimaryPressed: () {},
      onSecondaryPressed: () {},
    );
    return result ?? false;
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
