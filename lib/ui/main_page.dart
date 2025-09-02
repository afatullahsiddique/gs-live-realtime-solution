import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/cubits/app_cubit.dart';
import '../navigation/my_bottom_navigation.dart';
import '../navigation/routes.dart';
import '../theme/app_theme.dart';

class MainPage extends StatefulWidget {
  final Widget child;
  final int? selectedPageNo;

  const MainPage({super.key, required this.child, this.selectedPageNo});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.selectedPageNo ?? 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedPosition = index;
    });

    switch (index) {
      case 0:
        context.push(Routes.home.path);
        break;
      case 1:
        context.push(Routes.offer.path);
        break;
      case 2:
        context.go(Routes.qrCode.path);
        break;
      case 3:
        context.push(Routes.history.path);
        break;
      case 4:
        context.push(Routes.more.path);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: SafeArea(
            top: false,
            child: MyBottomNavBar(
              selectedPosition: _selectedPosition,
              onItemTapped: _onItemTapped,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: SizedBox(
            height: 60,
            width: 60,
            child: FloatingActionButton(
              onPressed: () => _onItemTapped(2),
              elevation: 6,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A90E2),
                      Color(0xFF6B5BFF),
                      Color(0xFF9013FE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
          body: widget.child,
        );
      },
    );
  }
}
