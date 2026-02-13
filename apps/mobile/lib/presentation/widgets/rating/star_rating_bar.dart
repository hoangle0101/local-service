import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// StarRatingBar - Interactive star rating widget
/// Allows users to select rating by tapping or dragging
class StarRatingBar extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double starSize;
  final Function(int) onRatingChanged;
  final bool readOnly;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingBar({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starSize = 40.0,
    required this.onRatingChanged,
    this.readOnly = false,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.grey300,
  });

  @override
  State<StarRatingBar> createState() => _StarRatingBarState();
}

class _StarRatingBarState extends State<StarRatingBar> {
  late int _currentRating;
  late int _hoverRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _hoverRating = 0;
  }

  @override
  void didUpdateWidget(StarRatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  void _onStarTapped(int rating) {
    if (!widget.readOnly) {
      setState(() => _currentRating = rating);
      widget.onRatingChanged(rating);
    }
  }

  void _onStarHovered(int rating) {
    if (!widget.readOnly) {
      setState(() => _hoverRating = rating);
    }
  }

  void _onHoverExit() {
    if (!widget.readOnly) {
      setState(() => _hoverRating = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _onHoverExit(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.maxRating, (index) {
            final rating = index + 1;
            final isActive = _hoverRating > 0
                ? rating <= _hoverRating
                : rating <= _currentRating;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.starSize * 0.15),
              child: GestureDetector(
                onTap: () => _onStarTapped(rating),
                child: MouseRegion(
                  onEnter: (_) => _onStarHovered(rating),
                  cursor: widget.readOnly
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: AnimatedScale(
                    scale: (_hoverRating > 0 && rating <= _hoverRating) ||
                            (rating <= _currentRating && _hoverRating == 0)
                        ? 1.1
                        : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.star_rounded,
                      size: widget.starSize,
                      color:
                          isActive ? widget.activeColor : widget.inactiveColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Star rating display widget - read-only version for showing reviews
class StarRatingDisplay extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? labelStyle;
  final bool showLabel;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 16.0,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.grey300,
    this.labelStyle,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ...List.generate(maxRating, (index) {
              final isActive = index < rating;
              return Padding(
                padding: EdgeInsets.only(right: starSize * 0.25),
                child: Icon(
                  isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: starSize,
                  color: isActive ? activeColor : inactiveColor,
                ),
              );
            }),
          ],
        ),
        if (showLabel) ...[
          SizedBox(width: starSize * 0.5),
          Text(
            '$rating/$maxRating',
            style: labelStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
          ),
        ],
      ],
    );
  }
}

/// Horizontal bar showing rating distribution
class RatingDistributionBar extends StatelessWidget {
  final int rating;
  final int count;
  final int totalReviews;
  final double barHeight;
  final Color barColor;

  const RatingDistributionBar({
    super.key,
    required this.rating,
    required this.count,
    required this.totalReviews,
    this.barHeight = 8.0,
    this.barColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;

    return Row(
      children: [
        Text(
          '$rating★',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: barHeight,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
