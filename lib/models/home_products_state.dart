class HomeProductsState {
  final bool isLoadingSections;
  final List<dynamic> sections;
  final List<dynamic> visibleSections;
  final Map<int, List<dynamic>> products;
  final Map<int, int> productPage;
  final Map<int, bool> hasMoreProducts;
  final Map<int, bool> isLoadingProducts;
  final int currentSectionIndex;

  const HomeProductsState({
    required this.isLoadingSections,
    required this.sections,
    required this.visibleSections,
    required this.products,
    required this.productPage,
    required this.hasMoreProducts,
    required this.isLoadingProducts,
    required this.currentSectionIndex,
  });

  factory HomeProductsState.initial() {
    return const HomeProductsState(
      isLoadingSections: true,
      sections: [],
      visibleSections: [],
      products: {},
      productPage: {},
      hasMoreProducts: {},
      isLoadingProducts: {},
      currentSectionIndex: 0,
    );
  }

  HomeProductsState copyWith({
    bool? isLoadingSections,
    List<dynamic>? sections,
    List<dynamic>? visibleSections,
    Map<int, List<dynamic>>? products,
    Map<int, int>? productPage,
    Map<int, bool>? hasMoreProducts,
    Map<int, bool>? isLoadingProducts,
    int? currentSectionIndex,
  }) {
    return HomeProductsState(
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      sections: sections ?? this.sections,
      visibleSections: visibleSections ?? this.visibleSections,
      products: products ?? this.products,
      productPage: productPage ?? this.productPage,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
    );
  }
}
