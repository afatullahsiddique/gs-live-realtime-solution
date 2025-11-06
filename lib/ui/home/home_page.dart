import 'dart:developer';
import 'package:cute_live/ui/home/tabs/party_tab.dart';
import 'package:cute_live/ui/home/tabs/pk_tab.dart';
import 'package:cute_live/ui/home/widgets/card_widget.dart';
import 'package:cute_live/ui/home/widgets/carousal_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../core/cubits/app_cubit.dart';
import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';
import 'home_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<StreamerModel> _streamers = [
    StreamerModel(
      id: '1',
      name: 'Emma Rose',
      bio: 'Playing the latest RPGs and open-world adventures. Join the journey!',
      viewCount: 1234,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      isPremium: true,
      isVideo: true,
    ),
    StreamerModel(
      id: '2',
      name: 'Alex Chen',
      bio: 'Interactive art streams and digital painting. Let\'s create together!',
      viewCount: 987,
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      isPremium: true,
      isVideo: true,
    ),
    StreamerModel(
      id: '3',
      name: 'Sophie Kim',
      bio: 'Live music sessions and acoustic covers. Request your favorite songs!',
      viewCount: 2156,
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      isPremium: false,
      isVideo: false,
    ),
    StreamerModel(
      id: '4',
      name: 'Ryan Miller',
      bio: 'Competitive gaming and esports analysis. Let\'s talk strategy!',
      viewCount: 754,
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
      isPremium: false,
      isVideo: true,
    ),
    StreamerModel(
      id: '5',
      name: 'Sophie Kim',
      bio: 'Live music sessions and acoustic covers. Request your favorite songs!',
      viewCount: 2156,
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      isPremium: false,
      isVideo: false,
    ),
    StreamerModel(
      id: '6',
      name: 'Ryan Miller',
      bio: 'Competitive gaming and esports analysis. Let\'s talk strategy!',
      viewCount: 754,
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
      isPremium: false,
      isVideo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..init(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<HomeCubit>();
          return Scaffold(
            appBar: _buildNewAppBar(),
            body: Container(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(child: _buildPopularGrid(cubit)),
                          SingleChildScrollView(child: _buildFresherGrid(cubit)),
                          PartyTab(streamers: _streamers),
                          PKTab(streamers: _streamers),
                          _buildGamesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildNewAppBar() {
    return AppBar(
      backgroundColor: Colors.pink,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: Align(
        alignment: Alignment.centerLeft,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          tabs: const [
            Tab(text: 'Popular'),
            Tab(text: 'Freshers'),
            Tab(text: 'Party'),
            Tab(text: 'PK'),
            Tab(text: 'Games'),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white, size: 24),
          onPressed: () {
            // Handle search
          },
        ),
        GestureDetector(
          onTap: () {
            context.push(Routes.myLevel.path);
          },
          onLongPress: () {
            final appCubit = GetIt.I<AppCubit>();
            appCubit.logout();
            context.go(Routes.login.path);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.emoji_events_outlined, color: Colors.amber[700], size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildFresherGrid(HomeCubit cubit) {
    return Column(
      children: [
        CarouselBanner(
          imageUrls: BannerUrls.liveStreamingBanners,
          height: 120,
          autoPlayDuration: const Duration(seconds: 4),
          onBannerTap: (index) {
            print('Banner $index tapped');
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            // Add this line
            physics: const NeverScrollableScrollPhysics(),
            // Add this line
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
      ],
    );
  }

  Widget _buildPopularGrid(HomeCubit cubit) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 10, bottom: 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .9,
            ),
            itemCount: 2,
            // Showing first 2 static items
            itemBuilder: (context, index) {
              return AnimatedStreamerCard(streamer: _streamers[index], index: index);
            },
          ),
        ),
        // Your static banner
        CarouselBanner(
          imageUrls: BannerUrls.liveStreamingBanners,
          height: 120,
          autoPlayDuration: const Duration(seconds: 4),
          onBannerTap: (index) {
            print('Banner $index tapped');
          },
        ),
        StreamBuilder<List<StreamerModel>>(
          stream: cubit.allRoomsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              log("Error in StreamBuilder: ${snapshot.error}");
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final liveRooms = snapshot.data!;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 0, bottom: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .9,
                ),
                itemCount: liveRooms.length,
                itemBuilder: (context, index) {
                  return AnimatedStreamerCard(streamer: liveRooms[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGamesTab() {
    final List<Map<String, String>> games = [
      {'name': 'Greedy', 'image': 'assets/greedy/greedy_icon.png', 'path': Routes.greedy.path},
      {'name': 'Tin Patti', 'image': 'assets/icons/tin_patti_icon.png'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          CarouselBanner(
            imageUrls: BannerUrls.liveStreamingBanners,
            autoPlayDuration: const Duration(seconds: 4),
            onBannerTap: (index) {
              log('Game Banner $index tapped');
            },
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Featured Games',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Building the game list using a 2-column grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85, // Adjust this for a rectangle/square look
                  ),
                  itemBuilder: (context, index) {
                    return _buildGameCard(games[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, String> game) {
    final String name = game['name']!;
    final String imagePath = game['image']!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Icon (takes up the available space)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.pinkDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gamepad, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. Game Name
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // 3. Play Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (game['path'] != null) {
                    context.push(game['path']!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pinkLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Play Now', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamerModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String bio;
  final int viewCount;
  final bool isPremium;
  final bool isVideo;
  final bool isLocked;
  final bool isLiveStream;

  const StreamerModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.bio,
    required this.viewCount,
    this.isPremium = false,
    this.isVideo = true,
    this.isLocked = false,
    this.isLiveStream = false,
  });
}
