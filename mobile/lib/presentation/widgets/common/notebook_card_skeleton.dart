import 'package:flutter/material.dart';
import '../../../config/theme/spacing.dart';
import 'shimmer_skeleton.dart';

class NotebookCardSkeleton extends StatelessWidget {
  const NotebookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Spacing.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Spacing.radiusMd),
                  topRight: Radius.circular(Spacing.radiusMd),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 40, height: 40),
                  SizedBox(height: Spacing.sm),
                  ShimmerLine(width: 100, height: 14),
                  SizedBox(height: Spacing.xs),
                  ShimmerLine(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
