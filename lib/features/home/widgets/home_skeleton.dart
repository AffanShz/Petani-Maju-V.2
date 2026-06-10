import 'package:flutter/material.dart';
import 'package:petani_maju/widgets/skeleton_container.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom App Bar Skeleton
            Row(
              children: [
                const SkeletonContainer.circular(width: 48, height: 48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonContainer.square(width: 120, height: 20),
                    SizedBox(height: 8),
                    SkeletonContainer.square(width: 80, height: 14),
                  ],
                ),
                const Spacer(),
                const SkeletonContainer.circular(width: 40, height: 40),
              ],
            ),
            const SizedBox(height: 16),
            // Sync Status Bar Skeleton
            const Center(
              child: SkeletonContainer.square(
                width: double.infinity,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            const SizedBox(height: 20),

            // Main Weather Card Skeleton
            const SkeletonContainer.square(
              width: double.infinity,
              height: 160,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const SizedBox(height: 20),

            // Section Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonContainer.square(width: 140, height: 24),
                SkeletonContainer.square(width: 60, height: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Forecast List Skeleton
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => const SkeletonContainer.square(
                  width: 110,
                  height: 190,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonContainer.square(width: 140, height: 24),
                SkeletonContainer.square(width: 60, height: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Tips List Skeleton
            Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: const [
                      SkeletonContainer.square(
                        width: 80,
                        height: 80,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonContainer.square(
                                width: double.infinity, height: 16),
                            SizedBox(height: 8),
                            SkeletonContainer.square(width: 140, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
