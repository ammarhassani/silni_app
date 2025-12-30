import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';

class SkeletonLoader extends ConsumerWidget {
  final double width;
  final double height;
  final double borderRadius;
  final String? semanticsLabel;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: semanticsLabel ?? 'جاري التحميل',
      child: Shimmer.fromColors(
        baseColor: themeColors.shimmerBase,
        highlightColor: themeColors.shimmerHighlight,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: themeColors.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class CircleSkeletonLoader extends ConsumerWidget {
  final double size;
  final String? semanticsLabel;

  const CircleSkeletonLoader({
    super.key,
    required this.size,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: semanticsLabel ?? 'جاري التحميل',
      child: Shimmer.fromColors(
        baseColor: themeColors.shimmerBase,
        highlightColor: themeColors.shimmerHighlight,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors.glassBackground,
          ),
        ),
      ),
    );
  }
}

class FamilyCirclesSkeleton extends StatelessWidget {
  const FamilyCirclesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جاري تحميل دوائر العائلة',
      child: Column(
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
      ),
    );
  }
}

class RelativeCardSkeleton extends ConsumerWidget {
  const RelativeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'جاري تحميل بطاقة القريب',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: themeColors.glassBorder,
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
      ),
    );
  }
}

/// Skeleton loader for Hadith card
class HadithSkeletonLoader extends ConsumerWidget {
  const HadithSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'جاري تحميل الحديث',
      child: Container(
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
              color: themeColors.divider,
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
      ),
    );
  }
}

/// Skeleton loader for FrequencyCarousel (tomorrow/yesterday reminders)
class FrequencyCarouselSkeleton extends StatelessWidget {
  const FrequencyCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جاري تحميل التذكيرات',
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SkeletonLoader(
                width: 100,
                height: 70,
                borderRadius: AppSpacing.radiusMd,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton loader for DueRemindersCard
class DueRemindersCardSkeleton extends ConsumerWidget {
  const DueRemindersCardSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'جاري تحميل التذكيرات المستحقة',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: themeColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 140, height: 20, borderRadius: 4),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const CircleSkeletonLoader(size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonLoader(width: 100, height: 14, borderRadius: 4),
                          SizedBox(height: 4),
                          SkeletonLoader(width: 60, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for TodaysActivityWidget
class TodaysActivitySkeleton extends ConsumerWidget {
  const TodaysActivitySkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Semantics(
      label: 'جاري تحميل نشاط اليوم',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: themeColors.glassBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: themeColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 120, height: 20, borderRadius: 4),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const CircleSkeletonLoader(size: 36),
                    const SizedBox(width: AppSpacing.sm),
                    const SkeletonLoader(width: 80, height: 14, borderRadius: 4),
                    const Spacer(),
                    const SkeletonLoader(width: 50, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
