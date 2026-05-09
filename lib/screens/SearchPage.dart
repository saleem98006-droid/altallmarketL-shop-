import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home/product_card.dart'; // ← استيراد البطاقة

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  int? shopId;

  List<dynamic> results = [];
  bool isLoading = false;
  bool isSearching = false;

  int page = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadShopId();

    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  void _loadShopId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      shopId = prefs.getInt("shopId");
    });
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.trim().isNotEmpty) {
        _startSearch(text);
      } else {
        if (!mounted) return;
        setState(() {
          results.clear();
          isSearching = false;
        });
      }
    });
  }

  Future<void> _startSearch(String query) async {
    if (shopId == null) return;

    if (!mounted) return;
    setState(() {
      isLoading = true;
      isSearching = true;
      page = 1;
      hasMore = true;
    });

    final data = await ApiService.searchProducts(
      shopId: shopId!,
      query: query,
      page: page,
      pageSize: 20,
    );

    if (!mounted) return;
    setState(() {
      results = data ?? [];
      isLoading = false;
      hasMore = (data != null && data.length == 20);
    });
  }

  Future<void> _loadMore() async {
    if (!hasMore || isLoading || shopId == null) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    page++;
    final data = await ApiService.searchProducts(
      shopId: shopId!,
      query: _controller.text,
      page: page,
      pageSize: 20,
    );

    if (!mounted) return;
    setState(() {
      if (data != null && data.isNotEmpty) {
        results.addAll(data);
        hasMore = data.length == 20;
      } else {
        hasMore = false;
      }
      isLoading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: Colors.white,

    body: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.1), // 🔵 5% أعلى الصفحة

          _buildSearchBar(),

          SizedBox(height: screenHeight * 0.05), // 🔵 5% بعد شريط البحث

          SizedBox(
            height: screenHeight * 0.80, // مساحة للنتائج
            child: isSearching
                ? _buildResults()
                : _buildEmptyState(),
          ),
        ],
      ),
    ),
  );
}

 Widget _buildSearchBar() {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontFamily: 'Tajawal'),
        decoration: InputDecoration(
          hintText: "ابحث عن منتج...",
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              "assets/images/search.png",
              height: 20,
              width: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFF5A9BD5),
              width: 3,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFF5A9BD5),
              width: 3,
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "ابدأ بالبحث عن المنتجات",
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildResults() {
  return NotificationListener<ScrollNotification>(
    onNotification: (scroll) {
      if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent) {
        _loadMore();
      }
      return false;
    },
    child: ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = results[index];
        return _buildProductCard(product);
      },
    ),
  );
}

  Widget _buildProductCard(dynamic product) {
    return ProductCard(
      product: product,
      searchQuery: _controller.text,
    );
  }
}

