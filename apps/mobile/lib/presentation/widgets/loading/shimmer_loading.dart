import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerServiceCard extends StatelessWidget {
  const ShimmerServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLoading(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                        width: 100,
                        height: 12,
                        borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
              width: double.infinity,
              height: 20,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          ShimmerLoading(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 4),
          ShimmerLoading(
              width: 200, height: 14, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading(
                  width: 100,
                  height: 24,
                  borderRadius: BorderRadius.circular(4)),
              ShimmerLoading(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20)),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerCategoryCard extends StatelessWidget {
  const ShimmerCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ShimmerLoading(
              width: 64, height: 64, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 8),
          ShimmerLoading(
              width: 60, height: 12, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}
