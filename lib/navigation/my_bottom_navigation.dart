import 'package:flutter/material.dart';
import 'dart:ui';

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
  late List<Animation<double>> _glowAnimations;

  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    NavBarItem(icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, label: 'Live'),
    NavBarItem(icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded, label: 'Create', isCenter: true),
    NavBarItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Inbox'),
    NavBarItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(_navItems.length, (index) => AnimationController(duration: const Duration(milliseconds: 200), vsync: this));

    _scaleAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)))
        .toList();

    _glowAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)))
        .toList();

    // Animate the initially selected item
    if (widget.selectedPosition < _animationControllers.length) {
      _animationControllers[widget.selectedPosition].forward();
    }
  }

  @override
  void didUpdateWidget(MyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPosition != widget.selectedPosition) {
      // Reset all animations
      for (var controller in _animationControllers) {
        controller.reset();
      }
      // Animate the new selected item
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
      height: 90,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black.withOpacity(0.8), Colors.pink.shade900.withOpacity(0.3), Colors.black.withOpacity(0.9)],
        ),
        border: Border.all(color: Colors.pink.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 0)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index, _navItems[index]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavBarItem item) {
    final isSelected = widget.selectedPosition == index;
    final isCenter = item.isCenter;

    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimations[index], _glowAnimations[index]]),
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              widget.onItemTapped(index);
              _animationControllers[index].forward();
            },
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    width: isCenter ? 50 : 40,
                    height: isCenter ? 50 : 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isCenter ? 25 : 20),
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isCenter
                                  ? [Colors.pink.shade400, Colors.pink.shade600, Colors.pink.shade800]
                                  : [Colors.pink.shade300.withOpacity(0.3), Colors.pink.shade500.withOpacity(0.2)],
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.4),
                                blurRadius: 15 * _glowAnimations[index].value,
                                spreadRadius: 2 * _glowAnimations[index].value,
                              ),
                            ]
                          : null,
                    ),
                    child: Transform.scale(
                      scale: _scaleAnimations[index].value,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        size: isCenter ? 28 : 24,
                      ),
                    ),
                  ),

                  // Label (only for non-center items when selected)
                  if (!isCenter && isSelected) ...[
                    const SizedBox(height: 4),
                    AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        item.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.pink.shade300),
                      ),
                    ),
                  ],

                  // Indicator dot for center item
                  if (isCenter) ...[
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 6 : 4,
                      height: isSelected ? 6 : 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  NavBarItem({required this.icon, required this.activeIcon, required this.label, this.isCenter = false});
}
