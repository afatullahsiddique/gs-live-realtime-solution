import 'package:flutter/material.dart';

class MyBottomNavBar extends StatefulWidget {
  final int selectedPosition;
  final Function(int) onItemTapped;

  const MyBottomNavBar({super.key, required this.selectedPosition, required this.onItemTapped});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_outlined, label: 'Home'),
    NavBarItem(icon: Icons.social_distance_outlined, activeIcon: Icons.social_distance_outlined, label: 'Social'),
    NavBarItem(icon: Icons.shopping_cart_checkout_outlined, activeIcon: Icons.shopping_cart_checkout_outlined, label: 'Marketplace'),
    NavBarItem(icon: Icons.message_outlined, activeIcon: Icons.message_outlined, label: 'Inbox', badge: '26'),
    NavBarItem(icon: Icons.person, activeIcon: Icons.person, label: 'Me'),
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      _navItems.length,
          (index) => AnimationController(duration: const Duration(milliseconds: 250), vsync: this),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) =>
          Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
    )
        .toList();

    if (widget.selectedPosition < _animationControllers.length) {
      _animationControllers[widget.selectedPosition].forward();
    }
  }

  @override
  void didUpdateWidget(MyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPosition != widget.selectedPosition) {
      for (var controller in _animationControllers) {
        controller.reset();
      }
      if (widget.selectedPosition < _animationControllers.length) {
        _animationControllers[widget.selectedPosition].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItems.length, (index) {
            return _buildNavItem(index, _navItems[index]);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavBarItem item) {
    final isSelected = widget.selectedPosition == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? _scaleAnimations[index].value : 1.0,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? const Color(0xFFC0A4FF) : const Color(0xFFC4C4D1),
                      size: index == 0 ? 32 : 30, // Drum icon slightly larger
                    ),
                  );
                },
              ),
              if (item.badge != null)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF456E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
  final String? badge;

  NavBarItem({
    required this.icon, 
    required this.activeIcon, 
    required this.label, 
    this.isCenter = false,
    this.badge,
  });
}
