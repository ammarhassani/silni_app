import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CircleSkeletonLoader extends StatelessWidget {
  final double size;

  const CircleSkeletonLoader({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
}

class FamilyCirclesSkeleton extends StatelessWidget {
  const FamilyCirclesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 100, height: 24),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  children: [
                    CircleSkeletonLoader(size: 70),
                    const SizedBox(height: 6),
                    SkeletonLoader(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RelativeCardSkeleton extends StatelessWidget {
  const RelativeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const CircleSkeletonLoader(size: 60),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 18,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 150,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for Hadith card
class HadithSkeletonLoader extends StatelessWidget {
  const HadithSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arabic text lines
          const SkeletonLoader(
            width: double.infinity,
            height: 22,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLoader(
            width: double.infinity,
            height: 22,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 22,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.md),

          // Divider
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: AppSpacing.md),

          // English translation lines
          const SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: AppSpacing.md),

          // Source
          const SkeletonLoader(
            width: 120,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
