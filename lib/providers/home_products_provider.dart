import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_products_state.dart';
import '../repositories/home_products_repository.dart';

final homeProductsRepositoryProvider = Provider<HomeProductsRepository>((ref) {
  return HomeProductsRepository();
});

final homeProductsProvider =
    StateNotifierProvider<HomeProductsNotifier, HomeProductsState>((ref) {
  final repository = ref.read(homeProductsRepositoryProvider);
  return HomeProductsNotifier(repository);
});

class HomeProductsNotifier extends StateNotifier<HomeProductsState> {
  HomeProductsNotifier(this._repository) : super(HomeProductsState.initial());

  final HomeProductsRepository _repository;

  Future<void> refreshSectionsOnly() async {
    state = HomeProductsState.initial();
    await loadSections();
  }

  Future<void> loadSections() async {
    try {
      final shopId = await _repository.getShopId();
      final sections = await _repository.getSectionsByShop(shopId);

      if (sections.isEmpty) {
        state = state.copyWith(
          isLoadingSections: false,
          sections: [],
          visibleSections: [],
        );
        return;
      }

      final products = <int, List<dynamic>>{};
      final productPage = <int, int>{};
      final hasMoreProducts = <int, bool>{};
      final isLoadingProducts = <int, bool>{};

      for (final sec in sections) {
        final id = sec['sectionId'] as int;
        products[id] = [];
        productPage[id] = 1;
        hasMoreProducts[id] = true;
        isLoadingProducts[id] = false;
      }

      state = state.copyWith(
        isLoadingSections: false,
        sections: sections,
        visibleSections: [sections.first],
        products: products,
        productPage: productPage,
        hasMoreProducts: hasMoreProducts,
        isLoadingProducts: isLoadingProducts,
        currentSectionIndex: 0,
      );

      await loadProductsForSection(sections.first['sectionId'] as int);
    } catch (_) {
      state = state.copyWith(
        isLoadingSections: false,
        visibleSections: [],
      );
    }
  }

  Future<void> loadProductsForSection(int sectionId) async {
    if (state.isLoadingProducts[sectionId] == true) return;
    if (state.hasMoreProducts[sectionId] == false) return;

    final loadingMap = Map<int, bool>.from(state.isLoadingProducts);
    loadingMap[sectionId] = true;
    state = state.copyWith(isLoadingProducts: loadingMap);

    final page = state.productPage[sectionId] ?? 1;
    final response = await _repository.getProductsBySection(
      sectionId: sectionId,
      page: page,
      pageSize: 6,
    );

    final newProducts = response?['products'] as List<dynamic>? ?? [];
    final total = response?['totalProducts'] as int? ?? 0;

    final productsMap = Map<int, List<dynamic>>.from(state.products);
    final currentProducts = List<dynamic>.from(productsMap[sectionId] ?? []);

    final pageMap = Map<int, int>.from(state.productPage);
    final hasMoreMap = Map<int, bool>.from(state.hasMoreProducts);
    final loadingMapDone = Map<int, bool>.from(state.isLoadingProducts);

    if (newProducts.isEmpty) {
      hasMoreMap[sectionId] = false;
    } else {
      currentProducts.addAll(newProducts);
      productsMap[sectionId] = currentProducts;
      pageMap[sectionId] = page + 1;

      if (currentProducts.length >= total) {
        hasMoreMap[sectionId] = false;
      }
    }

    loadingMapDone[sectionId] = false;

    state = state.copyWith(
      products: productsMap,
      productPage: pageMap,
      hasMoreProducts: hasMoreMap,
      isLoadingProducts: loadingMapDone,
    );

    if (newProducts.isNotEmpty) {
      await _loadNextSection();
    }
  }

  Future<void> refreshSection(int sectionId) async {
    final response = await _repository.getProductsBySection(
      sectionId: sectionId,
      page: 1,
      pageSize: 6,
    );

    final newProducts = response?['products'] as List<dynamic>? ?? [];
    final total = response?['totalProducts'] as int? ?? 0;

    final productsMap = Map<int, List<dynamic>>.from(state.products);
    final pageMap = Map<int, int>.from(state.productPage);
    final hasMoreMap = Map<int, bool>.from(state.hasMoreProducts);

    productsMap[sectionId] = newProducts;
    pageMap[sectionId] = 2;
    hasMoreMap[sectionId] = newProducts.length < total;

    state = state.copyWith(
      products: productsMap,
      productPage: pageMap,
      hasMoreProducts: hasMoreMap,
    );
  }

  Future<void> _loadNextSection() async {
    if (state.currentSectionIndex + 1 >= state.sections.length) return;

    final nextIndex = state.currentSectionIndex + 1;
    final nextSection = state.sections[nextIndex];

    state = state.copyWith(
      currentSectionIndex: nextIndex,
      visibleSections: [...state.visibleSections, nextSection],
    );

    await loadProductsForSection(nextSection['sectionId'] as int);
  }
}
