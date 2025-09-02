import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MyBottomNavBar extends StatelessWidget {
  final int selectedPosition;
  final Function(int) onItemTapped;

  const MyBottomNavBar({
    super.key,
    required this.selectedPosition,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      color: Colors.white,
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Icon + Label
          InkWell(
            onTap: () => onItemTapped(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selectedPosition == 0 ? Icons.home : Icons.home_outlined,
                  color: selectedPosition == 0
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  'Home',
                  style: TextStyle(
                    color: selectedPosition == 0
                        ? AppColors.primary
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Offers Icon + Label
          InkWell(
            onTap: () => onItemTapped(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selectedPosition == 1
                      ? Icons.local_offer
                      : Icons.local_offer_outlined,
                  color: selectedPosition == 1
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  'Offers',
                  style: TextStyle(
                    color: selectedPosition == 1
                        ? AppColors.primary
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Spacer for FAB
          const SizedBox(width: 56),

          // History Icon + Label
          InkWell(
            onTap: () => onItemTapped(3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selectedPosition == 3
                      ? Icons.bar_chart
                      : Icons.bar_chart_outlined,
                  color: selectedPosition == 3
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  'History',
                  style: TextStyle(
                    color: selectedPosition == 3
                        ? AppColors.primary
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // More Icon + Label
          InkWell(
            onTap: () => onItemTapped(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selectedPosition == 4
                      ? Icons.more_vert
                      : Icons.more_vert_outlined,
                  color: selectedPosition == 4
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  'More',
                  style: TextStyle(
                    color: selectedPosition == 4
                        ? AppColors.primary
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
