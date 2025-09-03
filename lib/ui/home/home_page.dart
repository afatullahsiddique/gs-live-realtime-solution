import 'package:cute_live/ui/home/widgets/card_widget.dart';
import 'package:cute_live/ui/home/widgets/carousal_banner.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../../core/utils/view_count.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for streamers
  final List<StreamerModel> _streamers = [
    StreamerModel(
      id: '1',
      name: 'Emma Rose',
      viewCount: 1234,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      isPremium: true,
      isVideo: true,
    ),
    StreamerModel(
      id: '2',
      name: 'Alex Chen',
      viewCount: 987,
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      isPremium: true,
      isVideo: true,
    ),
    StreamerModel(
      id: '3',
      name: 'Sophie Kim',
      viewCount: 2156,
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      isPremium: false,
      isVideo: false,
    ),
    StreamerModel(
      id: '4',
      name: 'Ryan Miller',
      viewCount: 754,
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
      isPremium: false,
      isVideo: true,
    ),
    StreamerModel(
      id: '5',
      name: 'Luna Park',
      viewCount: 3421,
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      isPremium: false,
    ),
    StreamerModel(
      id: '6',
      name: 'Jake Wilson',
      viewCount: 892,
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      isPremium: false,
    ),
    StreamerModel(
      id: '7',
      name: 'Mia Johnson',
      viewCount: 1567,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      isPremium: false,
      isVideo: false,
    ),
    StreamerModel(
      id: '8',
      name: 'Chris Brown',
      viewCount: 445,
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      isPremium: false,
    ),
  ];

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b), Color(0xFF4a2c4a), Color(0xFFff6b9d)],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStreamersGrid('Popular'),
                    _buildStreamersGrid('Freshers'),
                    _buildStreamersGrid('Party'),
                    _buildStreamersGrid('PK'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Profile Section
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500]),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Colors.white, size: 24);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(colors: [Colors.white, Colors.pink.shade200]).createShader(bounds),
                    child: const Text(
                      'John Doe',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'ID: 123456789',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Settings Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.2),
              border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_rounded, color: Colors.pink.shade300, size: 20),
              onPressed: () {
                // Navigate to settings
              },
            ),
          ),
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
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Popular'),
          Tab(text: 'Freshers'),
          Tab(text: 'Party'),
          Tab(text: 'PK'),
        ],
      ),
    );
  }

  Widget _buildStreamersGrid(String category) {
    return Column(
      children: [
        if (category == "Freshers")
          CarouselBanner(
            imageUrls: BannerUrls.liveStreamingBanners,
            height: 180,
            autoPlayDuration: const Duration(seconds: 4),
            onBannerTap: (index) {
              // Handle banner tap
              print('Banner $index tapped');
            },
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .9,
              ),
              itemCount: _streamers.length,
              itemBuilder: (context, index) {
                return AnimatedStreamerCard(streamer: _streamers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StreamerModel {
  final String id;
  final String name;
  final String imageUrl;
  final int viewCount;
  final bool isPremium;
  final bool isVideo;

  const StreamerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.viewCount,
    this.isPremium = false,
    this.isVideo = true,
  });
}
