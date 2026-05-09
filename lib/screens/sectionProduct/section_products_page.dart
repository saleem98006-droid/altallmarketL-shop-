import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/app_events.dart';
import '../../providers/section_products_provider.dart';
import 'product_card_small.dart';

class SectionProductsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> section;

  const SectionProductsPage({
    super.key,
    required this.section,
  });

  @override
  ConsumerState<SectionProductsPage> createState() =>
      _SectionProductsPageState();
}

class _SectionProductsPageState extends ConsumerState<SectionProductsPage> {
  StreamSubscription<String>? _eventSubscription;

  int get _sectionId => (widget.section['sectionId'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(sectionProductsProvider(_sectionId).notifier).init();
    });

    _eventSubscription = AppEvents().stream.listen((event) {
      if (event == 'refresh_section_products') {
        if (!mounted) return;
        ref
            .read(sectionProductsProvider(_sectionId).notifier)
            .loadProducts(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Widget buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 900),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sectionName = widget.section['sectionName'] ?? 'قسم';
    final double screenHeight = MediaQuery.of(context).size.height;
    final sectionState = ref.watch(sectionProductsProvider(_sectionId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: Text(
                sectionName,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.blue,
                onRefresh: () => ref
                    .read(sectionProductsProvider(_sectionId).notifier)
                    .loadProducts(refresh: true),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: screenHeight * 0.05),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = sectionState.products[index];

                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              switchInCurve: Curves.easeIn,
                              switchOutCurve: Curves.easeOut,
                              child: item == null
                                  ? buildShimmerItem()
                                  : ProductCardSmall(
                                      key: ValueKey(item['productId']),
                                      product: item,
                                    ),
                            );
                          },
                          childCount: sectionState.products.length,
                        ),
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
