import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_products_provider.dart';

class SectionProductsState {
  final List<Map<String, dynamic>?> products;
  final int page;
  final int pageSize;
  final bool isLoading;
  final bool hasMore;
  final bool isRefreshing;

  const SectionProductsState({
    required this.products,
    required this.page,
    required this.pageSize,
    required this.isLoading,
    required this.hasMore,
    required this.isRefreshing,
  });

  factory SectionProductsState.initial({int pageSize = 6}) {
    return SectionProductsState(
      products: const [],
      page: 1,
      pageSize: pageSize,
      isLoading: false,
      hasMore: true,
      isRefreshing: false,
    );
  }

  SectionProductsState copyWith({
    List<Map<String, dynamic>?>? products,
    int? page,
    int? pageSize,
    bool? isLoading,
    bool? hasMore,
    bool? isRefreshing,
  }) {
    return SectionProductsState(
      products: products ?? this.products,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class SectionProductsNotifier extends StateNotifier<SectionProductsState> {
  SectionProductsNotifier(this.ref, this.sectionId)
      : super(SectionProductsState.initial());

  final Ref ref;
  final int sectionId;

  Future<void> init() async {
    if (state.products.isNotEmpty || state.isLoading) return;
    await loadProducts();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        page: 1,
        products: List<Map<String, dynamic>?>.filled(state.pageSize, null),
        hasMore: true,
        isRefreshing: true,
        isLoading: false,
      );
    }

    if (!state.hasMore) return;

    final beforeLoad = List<Map<String, dynamic>?>.from(state.products);
    if (!refresh) {
      beforeLoad.addAll(List<Map<String, dynamic>?>.filled(state.pageSize, null));
    }

    state = state.copyWith(
      products: beforeLoad,
      isLoading: true,
    );

    final shimmerStartIndex = state.products.length - state.pageSize;

    final repository = ref.read(homeProductsRepositoryProvider);
    final result = await repository.getProductsBySection(
      sectionId: sectionId,
      page: state.page,
      pageSize: state.pageSize,
    );

    final updated = List<Map<String, dynamic>?>.from(state.products);

    final canRemove =
        shimmerStartIndex >= 0 && shimmerStartIndex + state.pageSize <= updated.length;
    if (canRemove) {
      updated.removeRange(shimmerStartIndex, shimmerStartIndex + state.pageSize);
    }

    if (result != null && result['success'] == true) {
      final List<dynamic> raw = result['products'] ?? [];
      final int total = result['totalProducts'] ?? 0;

      if (raw.isNotEmpty) {
        final List<Map<String, dynamic>> newProducts = raw
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();

        updated.addAll(newProducts);

        final loadedCount = updated.where((e) => e != null).length;
        final hasMore = loadedCount < total;

        state = state.copyWith(
          products: updated,
          page: hasMore ? state.page + 1 : state.page,
          hasMore: hasMore,
          isLoading: false,
          isRefreshing: false,
        );
      } else {
        state = state.copyWith(
          products: updated,
          hasMore: false,
          isLoading: false,
          isRefreshing: false,
        );
      }
    } else {
      state = state.copyWith(
        products: updated,
        isLoading: false,
        isRefreshing: false,
      );
    }

    if (state.hasMore && !state.isRefreshing) {
      await Future<void>.microtask(() async => loadProducts());
    }
  }
}

final sectionProductsProvider = StateNotifierProvider.family<
    SectionProductsNotifier,
    SectionProductsState,
    int>((ref, sectionId) {
  return SectionProductsNotifier(ref, sectionId);
});
