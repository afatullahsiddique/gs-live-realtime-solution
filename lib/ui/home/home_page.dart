import 'dart:developer';
import 'package:cute_live/ui/home/tabs/pk_tab.dart';
import 'package:cute_live/ui/home/widgets/card_widget.dart';
import 'package:cute_live/ui/home/widgets/carousal_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

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

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2d1b2b),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Exit App',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Do you really want to close the application?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..init(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<HomeCubit>();
          return WillPopScope(
            onWillPop: () async {
              final shouldExit = await _showExitConfirmationDialog();
              if (shouldExit) {
                SystemNavigator.pop(); // Completely closes the app
                return true;
              }
              return false;
            },
            child: Scaffold(
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
                            _buildPopularTab(cubit),
                            SingleChildScrollView(child: _buildFresherGrid(cubit)),
                            _buildPartyTab(cubit),
                            PKTab(streamers: _streamers),
                            _buildGamesTab(),
                          ],
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
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.emoji_events_outlined, color: Colors.amber[700], size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularTab(HomeCubit cubit) {
    return StreamBuilder<List<StreamerModel>>(
      stream: cubit.allRoomsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
          );
        }

        final allRooms = snapshot.data ?? [];

        // 1. Check for Empty State (UPDATED LOGIC)
        if (allRooms.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Show Banner First
                CarouselBanner(
                  imageUrls: BannerUrls.liveStreamingBanners,
                  autoPlayDuration: const Duration(seconds: 4),
                  onBannerTap: (index) {
                    print('Banner $index tapped');
                  },
                ),

                // Add some spacing
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                // Then show the empty state message
                Icon(Icons.videocam_off, size: 60, color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  "No room is currently active",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                ),
              ],
            ),
          );
        }

        // 2. Split logic: Top 2 vs The Rest
        // Since the list is already sorted by viewCount in the Cubit, we just take by index.
        final topTwoRooms = allRooms.take(2).toList();
        final restOfRooms = allRooms.skip(2).toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              // --- SECTION A: Top 2 Rooms ---
              if (topTwoRooms.isNotEmpty)
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
                    itemCount: topTwoRooms.length,
                    itemBuilder: (context, index) {
                      // Apply special SVGA animations for the top 2
                      final List<String> popularAnimationPaths = [
                        "assets/svga/room_cover_1.svga",
                        "assets/svga/room_cover_2.svga",
                      ];

                      String? animPath;
                      if (index < popularAnimationPaths.length) {
                        animPath = popularAnimationPaths[index];
                      }

                      return AnimatedStreamerCard(streamer: topTwoRooms[index], animationFilePath: animPath);
                    },
                  ),
                ),

              // --- SECTION B: Banner ---
              CarouselBanner(
                imageUrls: BannerUrls.liveStreamingBanners,
                autoPlayDuration: const Duration(seconds: 4),
                onBannerTap: (index) {
                  print('Banner $index tapped');
                },
              ),

              // --- SECTION C: Remaining Rooms ---
              if (restOfRooms.isNotEmpty)
                Container(
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
                    itemCount: restOfRooms.length,
                    itemBuilder: (context, index) {
                      return AnimatedStreamerCard(streamer: restOfRooms[index]);
                    },
                  ),
                ),

              const SizedBox(height: 80), // Bottom padding for navigation bar
            ],
          ),
        );
      },
    );
  }

  Widget _buildFresherGrid(HomeCubit cubit) {
    return StreamBuilder<List<StreamerModel>>(
      stream: cubit.freshersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              CarouselBanner(
                imageUrls: BannerUrls.liveStreamingBanners,
                autoPlayDuration: const Duration(seconds: 4),
                onBannerTap: (index) {
                  print('Banner $index tapped');
                },
              ),
              const SizedBox(height: 100),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              CarouselBanner(
                imageUrls: BannerUrls.liveStreamingBanners,
                autoPlayDuration: const Duration(seconds: 4),
                onBannerTap: (index) {
                  print('Banner $index tapped');
                },
              ),
              const SizedBox(height: 100),
              Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }

        final freshers = snapshot.data ?? [];

        if (freshers.isEmpty) {
          return Column(
            children: [
              CarouselBanner(
                imageUrls: BannerUrls.liveStreamingBanners,
                autoPlayDuration: const Duration(seconds: 4),
                onBannerTap: (index) {
                  print('Banner $index tapped');
                },
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Icon(Icons.videocam_off, size: 60, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text("No room is currently active", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
            ],
          );
        }

        return Column(
          children: [
            CarouselBanner(
              imageUrls: BannerUrls.liveStreamingBanners,
              autoPlayDuration: const Duration(seconds: 4),
              onBannerTap: (index) {
                print('Banner $index tapped');
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .9,
                ),
                itemCount: freshers.length,
                itemBuilder: (context, index) {
                  return AnimatedStreamerCard(streamer: freshers[index]);
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildPartyTab(HomeCubit cubit) {
    return StreamBuilder<List<StreamerModel>>(
      stream: cubit.audioRoomsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
          );
        }

        final audioRooms = snapshot.data ?? [];

        if (audioRooms.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              children: [
                CarouselBanner(
                  imageUrls: BannerUrls.liveStreamingBanners,
                  height: 120,
                  autoPlayDuration: const Duration(seconds: 4),
                  onBannerTap: (bannerIndex) {
                    print('Banner $bannerIndex tapped');
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Icon(Icons.mic_off, size: 60, color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  "No audio room is currently active",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: audioRooms.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // First item = Banner
              return CarouselBanner(
                imageUrls: BannerUrls.liveStreamingBanners,
                height: 120,
                autoPlayDuration: const Duration(seconds: 4),
                onBannerTap: (bannerIndex) {
                  print('Banner $bannerIndex tapped');
                },
              );
            }

            // Other items = Streamer cards
            final streamer = audioRooms[index - 1];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  // Use the same navigation logic as AnimatedStreamerCard
                  if (streamer.isLiveStream) {
                    context.push(Routes.liveStream.path, extra: {"roomId": streamer.id, "isHost": false});
                  } else if (!streamer.isVideo) {
                    context.push(Routes.audioRoom.path, extra: {"roomId": streamer.id, "isHost": false});
                  } else {
                    context.push(Routes.videoRoom.path, extra: {"roomId": streamer.id, "isHost": false});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Stack(
                    children: [
                      // Animated border overlay
                      if (index <= 3)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            "assets/animations/border_effect_$index.gif",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          ),
                        ),
                      // Semi-transparent overlay for better readability
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3), Colors.transparent],
                            stops: const [0.0, 0.6, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Content container
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Left side: Text content
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Streamer name with better contrast
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                                    ),
                                    child: Text(
                                      streamer.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54)],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Bio text - keeping empty as real data has empty bio
                                  if (streamer.bio.isNotEmpty)
                                    Text(
                                      streamer.bio,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                        shadows: const [
                                          Shadow(offset: Offset(0.5, 0.5), blurRadius: 2, color: Colors.black54),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const Spacer(),
                                  // Diamond count with icon (instead of view count)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility, size: 14, color: Colors.white.withOpacity(0.8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${streamer.viewCount}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right side: Profile image with enhanced styling
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: streamer.imageUrl != null
                                    ? Image.network(
                                        streamer.imageUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 40),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 40),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGamesTab() {
    final List<Map<String, String>> games = [
      {'name': 'Greedy', 'image': 'assets/greedy/greedy.jpeg', 'path': Routes.greedy.path},
      {'name': 'Fruits King', 'image': 'assets/spinner/fruits.jpeg', 'path': Routes.spinner.path},
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
