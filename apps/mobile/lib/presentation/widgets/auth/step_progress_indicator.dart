import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepTitles;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isActive = index == currentStep;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == totalSteps - 1 ? 0 : 4,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Step numbers with titles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isActive = index == currentStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : isActive
                              ? AppColors.primaryLight
                              : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted || isActive
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.grey.shade500,
                              ),
                            ),
                    ),
                  ),
                  if (stepTitles != null && index < stepTitles!.length) ...[
                    const SizedBox(height: 8),
                    Text(
                      stepTitles![index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : isCompleted
                                ? Colors.grey.shade700
                                : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
