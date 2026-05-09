import 'package:flutter/material.dart';

class LoadingDotsWidget extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;
  final Duration duration;

  const LoadingDotsWidget({
    super.key,
    this.color = const Color(0xFF5A9BD5),
    this.dotSize = 8,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<LoadingDotsWidget> createState() => _LoadingDotsWidgetState();
}

class _LoadingDotsWidgetState extends State<LoadingDotsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.2,
                    (index * 0.2) + 0.6,
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
