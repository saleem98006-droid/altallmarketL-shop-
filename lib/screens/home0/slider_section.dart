import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../providers/router_provider.dart';

class SliderSection extends StatefulWidget {
  final List sliders;
  final VoidCallback onSliderUpdated;

  const SliderSection({
    super.key,
    required this.sliders,
    required this.onSliderUpdated,
  });

  @override
  State<SliderSection> createState() => _SliderSectionState();
}

class _SliderSectionState extends State<SliderSection> {
  late PageController _pageController;
  Timer? _timer;

  List _sliders = [];
  int _page = 1;
  final int _pageSize = 5;

  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    _sliders = List.from(widget.sliders);

    _pageController = PageController(
      viewportFraction: 1,
      initialPage: _sliders.isNotEmpty ? _sliders.length - 1 : 0,
    );

    _pageController.addListener(_onScroll);

    if (_sliders.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadMore();
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (!_pageController.hasClients || _sliders.length <= 1) return;

      int currentPage = _pageController.page?.round() ?? 0;
      int nextPage = currentPage - 1;

      if (nextPage < 0) {
        _pageController.animateToPage(
          _sliders.length - 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant SliderSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sliders.length != widget.sliders.length) {
      _sliders = List.from(widget.sliders);

      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: 1,
        initialPage: _sliders.isNotEmpty ? _sliders.length - 1 : 0,
      );

      _pageController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page?.round() ?? 0;

    if (currentPage == 0 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    _page++;

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;

    final response = await ApiService.getActiveSlidersByShop(
      shopId,
      page: _page,
      pageSize: _pageSize,
    );

    if (response != null && response["sliders"] != null) {
      final List newSliders = response["sliders"];

      if (newSliders.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _sliders.addAll(newSliders);
        });
      }
    } else {
      _hasMore = false;
    }

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_sliders.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.25,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _sliders.length,
        reverse: true,
        padEnds: false,
        itemBuilder: (context, index) {
          final slider = _sliders[index];

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;

              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - (value * 0.06)).clamp(0.94, 1.0);
              }

              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: _buildSliderCard(slider),
          );
        },
      ),
    );
  }

  Widget _buildSliderCard(Map slider) {
    final title = slider['title']?.toString() ?? '';
    final imageUrl = slider['imageUrl']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        final result = await context.push(
          AppRoutes.editSlider,
          extra: slider,
        );

        if (result == true) {
          widget.onSliderUpdated();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: ApiConfig.baseUrl + imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}