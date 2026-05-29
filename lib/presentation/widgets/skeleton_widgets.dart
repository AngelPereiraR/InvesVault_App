import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      direction: ShimmerDirection.ltr,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? (Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[300]),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: 6);
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}

Widget _shimmerList({
  required int count,
  required double spacing,
  required EdgeInsets padding,
  required Widget Function(int index) itemBuilder,
}) {
  return AppShimmer(
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, i) => itemBuilder(i),
    ),
  );
}

// ─── Dashboard Skeleton ──────────────────────────────────────────────────────

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: _ == 0 ? 0 : 5,
                      right: _ == 2 ? 0 : 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        SkeletonBox(width: 24, height: 24, borderRadius: 12),
                        const SizedBox(height: 6),
                        SkeletonBox(width: 28, height: 16, borderRadius: 4),
                        const SizedBox(height: 2),
                        SkeletonBox(width: 48, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SkeletonBox(height: 48, borderRadius: 16),
            const SizedBox(height: 24),
            SkeletonBox(width: 120, height: 14, borderRadius: 4),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: List.generate(
                6,
                (_) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonBox(width: 52, height: 52, borderRadius: 26),
                    const SizedBox(height: 12),
                    SkeletonBox(width: 64, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 100, height: 14, borderRadius: 4),
                SkeletonBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.25,
              children: List.generate(
                2,
                (_) => Row(
                  children: [
                    SkeletonAvatar(size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SkeletonBox(width: 80, height: 12, borderRadius: 4),
                          const SizedBox(height: 4),
                          SkeletonBox(width: 60, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 80, height: 14, borderRadius: 4),
                SkeletonBox(width: 30, height: 20, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SkeletonBox(width: 20, height: 20, borderRadius: 4),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 14, borderRadius: 4),
                          const SizedBox(height: 4),
                          SkeletonBox(width: 80, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                    SkeletonBox(width: 20, height: 20, borderRadius: 4),
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

// ─── WarehouseList Skeleton ──────────────────────────────────────────────────

class WarehouseListSkeleton extends StatelessWidget {
  const WarehouseListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 6,
      spacing: 10,
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      itemBuilder: (_) => Row(
        children: [
          SkeletonAvatar(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140, height: 14),
                const SizedBox(height: 6),
                SkeletonLine(width: 80, height: 10),
              ],
            ),
          ),
          SkeletonBox(width: 24, height: 24, borderRadius: 4),
        ],
      ),
    );
  }
}

// ─── WarehouseDetail Skeleton ────────────────────────────────────────────────

class WarehouseDetailSkeleton extends StatelessWidget {
  const WarehouseDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 180, height: 20, borderRadius: 4),
            const SizedBox(height: 16),
            SkeletonBox(height: 44, borderRadius: 12),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkeletonBox(width: 80, height: 36, borderRadius: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 160, height: 14),
                          const SizedBox(height: 4),
                          SkeletonLine(width: 100, height: 11),
                          const SizedBox(height: 4),
                          SkeletonLine(width: 60, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SkeletonBox(width: 28, height: 28, borderRadius: 4),
                    const SizedBox(width: 4),
                    SkeletonBox(width: 28, height: 28, borderRadius: 4),
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

// ─── ProductList Skeleton ────────────────────────────────────────────────────

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 44, borderRadius: 12),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkeletonBox(width: 80, height: 36, borderRadius: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 56, height: 56, borderRadius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 180, height: 14),
                          const SizedBox(height: 6),
                          SkeletonLine(width: 120, height: 11),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SkeletonLine(width: 50, height: 11),
                              const Spacer(),
                              SkeletonBox(
                                width: 28,
                                height: 28,
                                borderRadius: 4,
                              ),
                              const SizedBox(width: 4),
                              SkeletonBox(
                                width: 28,
                                height: 28,
                                borderRadius: 4,
                              ),
                            ],
                          ),
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

// ─── Base list tile skeleton (shared by Store, Brand, Category) ─────────────

Widget _skeletonListItem(double width, double height) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      children: [
        SkeletonAvatar(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: width, height: height),
              const SizedBox(height: 4),
              SkeletonLine(width: width * 0.6, height: 11),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SkeletonBox(width: 28, height: 28, borderRadius: 4),
        const SizedBox(width: 4),
        SkeletonBox(width: 28, height: 28, borderRadius: 4),
      ],
    ),
  );
}

// ─── StoreList Skeleton ──────────────────────────────────────────────────────

class StoreListSkeleton extends StatelessWidget {
  const StoreListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 6,
      spacing: 4,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemBuilder: (_) => _skeletonListItem(120, 15),
    );
  }
}

// ─── BrandList Skeleton ──────────────────────────────────────────────────────

class BrandListSkeleton extends StatelessWidget {
  const BrandListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 6,
      spacing: 4,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemBuilder: (_) => _skeletonListItem(140, 15),
    );
  }
}

// ─── CategoryList Skeleton ───────────────────────────────────────────────────

class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 6,
      spacing: 4,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemBuilder: (_) => _skeletonListItem(130, 15),
    );
  }
}

// ─── StockChangeHistory Skeleton ─────────────────────────────────────────────

class StockChangeHistorySkeleton extends StatelessWidget {
  const StockChangeHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 52, borderRadius: 12),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child:
                        SkeletonBox(width: 90, height: 36, borderRadius: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonAvatar(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 160, height: 14),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SkeletonBox(
                                width: 40,
                                height: 22,
                                borderRadius: 6,
                              ),
                              const SizedBox(width: 8),
                              SkeletonLine(width: 80, height: 11),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SkeletonBox(
                                width: 14,
                                height: 14,
                                borderRadius: 7,
                              ),
                              const SizedBox(width: 4),
                              SkeletonLine(width: 60, height: 11),
                              const SizedBox(width: 12),
                              SkeletonBox(
                                width: 14,
                                height: 14,
                                borderRadius: 7,
                              ),
                              const SizedBox(width: 4),
                              SkeletonLine(width: 50, height: 11),
                            ],
                          ),
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

// ─── NotificationList Skeleton ───────────────────────────────────────────────

class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 6,
      spacing: 0,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SkeletonAvatar(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(
                    width: index.isEven ? 220 : 180,
                    height: 14,
                  ),
                  const SizedBox(height: 6),
                  SkeletonLine(width: 80, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ShoppingList Skeleton ───────────────────────────────────────────────────

class ShoppingListSkeleton extends StatelessWidget {
  const ShoppingListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerList(
      count: 4,
      spacing: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 100, height: 15),
          const SizedBox(height: 10),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SkeletonAvatar(size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(
                          width: i == 0 ? 180 : 140,
                          height: 14,
                        ),
                        const SizedBox(height: 4),
                        SkeletonLine(
                          width: i == 0 ? 100 : 60,
                          height: 11,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child:
                            SkeletonBox(width: 28, height: 28, borderRadius: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
