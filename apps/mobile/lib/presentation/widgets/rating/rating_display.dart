import 'package:flutter/material.dart';
import 'package:mobile/presentation/theme/app_colors.dart';


class RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.count,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: size - 2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
