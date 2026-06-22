import 'package:flutter/material.dart';
import '../../../config/theme/spacing.dart';
import 'shimmer_skeleton.dart';

class ListItemSkeleton extends StatelessWidget {
  final int count;

  const ListItemSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.screenPaddingH),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const _SkeletonItem(),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: ShimmerSkeleton(
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Spacing.borderRadiusMd,
          ),
          child: Row(
            children: const [
              ShimmerBox(width: 40, height: 40),
              SizedBox(width: Spacing.listItemGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(width: 140, height: 14),
                    SizedBox(height: Spacing.xs),
                    ShimmerLine(width: 80, height: 10),
                  ],
                ),
              ),
              ShimmerBox(width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
