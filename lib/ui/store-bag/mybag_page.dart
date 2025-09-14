import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

class MyBagPage extends StatefulWidget {
  const MyBagPage({super.key});

  @override
  State<MyBagPage> createState() => _MyBagPageState();
}

class _MyBagPageState extends State<MyBagPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for MyBag items
  final Map<String, List<StoreItemModel>> _storeItems = {
    'Ride': [
      StoreItemModel(
        id: '1',
        name: 'Golden Wings',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        price: 10000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '2',
        name: 'Dragon Ride',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        price: 25000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '3',
        name: 'Rainbow Unicorn',
        imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400',
        price: 15000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '4',
        name: 'Crystal Phoenix',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        price: 50000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '5',
        name: 'Magic Carpet',
        imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400',
        price: 8000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '6',
        name: 'Sky Chariot',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        price: 30000,
        duration: 'month',
      ),
    ],
    'Frame': [
      StoreItemModel(
        id: '7',
        name: 'Snow White Beer',
        imageUrl: 'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400',
        price: 5000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '8',
        name: 'Golden Crown',
        imageUrl: 'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=400',
        price: 20000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '9',
        name: 'Diamond Frame',
        imageUrl: 'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400',
        price: 35000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '10',
        name: 'Pink Roses',
        imageUrl: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=400',
        price: 12000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '11',
        name: 'Crystal Ice',
        imageUrl: 'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400',
        price: 18000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '12',
        name: 'Neon Glow',
        imageUrl: 'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=400',
        price: 22000,
        duration: 'month',
      ),
    ],
    'Entry': [
      StoreItemModel(
        id: '13',
        name: 'VIP Entrance',
        imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        price: 15000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '14',
        name: 'Royal Entry',
        imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400',
        price: 30000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '15',
        name: 'Diamond Door',
        imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        price: 45000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '16',
        name: 'Rainbow Portal',
        imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400',
        price: 25000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '17',
        name: 'Galaxy Gate',
        imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        price: 35000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '18',
        name: 'Pink Paradise',
        imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400',
        price: 20000,
        duration: 'month',
      ),
    ],
    'Bubble': [
      StoreItemModel(
        id: '19',
        name: 'Love Bubbles',
        imageUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400',
        price: 3000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '20',
        name: 'Rainbow Bubbles',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
        price: 5000,
        duration: 'week',
      ),
      StoreItemModel(
        id: '21',
        name: 'Crystal Bubbles',
        imageUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400',
        price: 8000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '22',
        name: 'Golden Bubbles',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
        price: 12000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '23',
        name: 'Magic Sparkles',
        imageUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400',
        price: 15000,
        duration: 'month',
      ),
      StoreItemModel(
        id: '24',
        name: 'Dream Bubbles',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
        price: 10000,
        duration: 'month',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(child: _buildStoreGrid('Ride')),
                    SingleChildScrollView(child: _buildStoreGrid('Frame')),
                    SingleChildScrollView(child: _buildStoreGrid('Entry')),
                    SingleChildScrollView(child: _buildStoreGrid('Bubble')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          // Store Title
          Expanded(
            child: const Text(
              'My Bag',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(),

          // Coins Display
          GestureDetector(
            onTap: () {
              context.push(Routes.store.path);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Store',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 0))],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Ride'),
              Tab(text: 'Frame'),
              Tab(text: 'Entry'),
              Tab(text: 'Bubble'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreGrid(String category) {
    final items = _storeItems[category] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return StoreItemCard(item: items[index]);
        },
      ),
    );
  }
}

class StoreItemCard extends StatefulWidget {
  final StoreItemModel item;

  const StoreItemCard({super.key, required this.item});

  @override
  State<StoreItemCard> createState() => _StoreItemCardState();
}

class _StoreItemCardState extends State<StoreItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        // Handle item purchase
        print('Tapped on ${widget.item.name}');
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4)),
                  if (_isPressed)
                    BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 0)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              widget.item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.pink.withOpacity(0.2),
                                  child: Icon(Icons.image, color: Colors.pink.shade300, size: 40),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Content Section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Item Name
                              Text(
                                widget.item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Price Section
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Colors.amber.shade300, Colors.amber.shade600]),
                                    ),
                                    child: const Icon(Icons.monetization_on, color: Colors.white, size: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${widget.item.price} beans/${widget.item.duration}',
                                      style: TextStyle(
                                        color: Colors.pink.shade300,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StoreItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final String duration;

  const StoreItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.duration,
  });
}
