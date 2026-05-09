import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SliderSection extends StatefulWidget {
  final List sliders;
  final List<ImageProvider> sliderImages;

  const SliderSection({
    super.key,
    required this.sliders,
    required this.sliderImages,
  });

  @override
  State<SliderSection> createState() => _SliderSectionState();
}

class _SliderSectionState extends State<SliderSection> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: widget.sliders.isNotEmpty ? widget.sliders.length - 1 : 0,
    );

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients || widget.sliders.length <= 1) return;

      int currentPage = _pageController.page?.round() ?? 0;
      int nextPage = currentPage - 1;

      if (nextPage < 0) {
        _pageController.animateToPage(
          widget.sliders.length - 1,
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
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliders.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.sliders.length,
          reverse: true,
          itemBuilder: (context, index) {
            final slider = widget.sliders[index];

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
              child: _buildSliderCard(slider, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliderCard(Map slider, int index) {
    final title = slider['title']?.toString() ?? '';

    Uint8List? imageBytes;
    try {
      final base64 = slider['image'];
      if (base64 != null && base64.isNotEmpty) {
        imageBytes = base64Decode(base64);
      }
    } catch (_) {}

    final imageWidget = imageBytes != null
        ? Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          )
        : Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
          );

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/editSlider',
          arguments: slider,
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(child: imageWidget),

              // العنوان فوق الصورة
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }
}