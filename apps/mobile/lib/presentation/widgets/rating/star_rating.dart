import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Modern star rating widget with smooth animations
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;
  final MainAxisAlignment alignment;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.showValue = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star_rounded;
            color = active;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
            color = active;
          } else {
            icon = Icons.star_outline_rounded;
            color = inactive;
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive star rating for user input
class InteractiveStarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const InteractiveStarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = rating >= starValue;

        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: isActive ? active : inactive,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Rating label based on star count
String getRatingLabel(int rating) {
  switch (rating) {
    case 1:
      return 'Rất tệ';
    case 2:
      return 'Tệ';
    case 3:
      return 'Bình thường';
    case 4:
      return 'Tốt';
    case 5:
      return 'Tuyệt vời';
    default:
      return '';
  }
}
