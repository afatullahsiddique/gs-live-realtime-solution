import 'package:flutter/material.dart';
import 'dart:async';

class CarouselBanner extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final Duration autoPlayDuration;
  final Function(int)? onBannerTap;

  const CarouselBanner({
    super.key,
    required this.imageUrls,
    this.height = 150,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.onBannerTap,
  });

  @override
  State<CarouselBanner> createState() => _CarouselBannerState();
}

class _CarouselBannerState extends State<CarouselBanner> {
  late PageController _pageController;
  late Timer _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (_currentIndex < widget.imageUrls.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => widget.onBannerTap?.call(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      widget.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white.withOpacity(0.5),
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    // Simple overlay to make content more readable on busy images
                    Container(color: Colors.black.withOpacity(0.1)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Sample banner URLs for your live streaming app
class BannerUrls {
  static const List<String> liveStreamingBanners = [
    'assets/banner/bd_admin.png',
    'assets/banner/india_admin.png',
    'assets/banner/india_admin_2.png',
    'assets/banner/pak_admin.png',
  ];
}
