import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cute_live/ui/home/tabs/party_tab.dart';
import 'package:cute_live/ui/home/tabs/pk_tab.dart';
import 'package:cute_live/ui/home/widgets/card_widget.dart';
import 'package:cute_live/ui/home/widgets/carousal_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:ui';

import '../../core/cubits/app_cubit.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../data/remote/firebase/video_room_services.dart';
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
  late Stream<List<StreamerModel>> _allRoomsStream;

  // Dummy data for streamers
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
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Get the individual streams
    final audioRoomsStream = RoomService.getAllRooms();
    final videoRoomsStream = VideoRoomService.getAllRooms();

    _allRoomsStream = CombineLatestStream.combine2(audioRoomsStream, videoRoomsStream, (
        QuerySnapshot audioSnapshot,
        QuerySnapshot videoSnapshot,
        ) {
      final List<StreamerModel> liveRooms = [];

      for (var doc in audioSnapshot.docs) {
        var roomData = doc.data() as Map<String, dynamic>;
        liveRooms.add(
          StreamerModel(
            id: doc.id,
            name: roomData['hostName'] ?? 'Unknown Host',
            imageUrl: roomData['hostPicture'],
            bio: '',
            viewCount: roomData['participantCount'] ?? 0,
            isVideo: false,
            isLocked: roomData['isLocked'] ?? false,
          ),
        );
      }

      // Process video rooms from the videoSnapshot
      for (var doc in videoSnapshot.docs) {
        var roomData = doc.data() as Map<String, dynamic>;
        liveRooms.add(
          StreamerModel(
            id: doc.id,
            name: roomData['hostName'] ?? 'Unknown Host',
            imageUrl: roomData['hostPicture'],
            bio: '',
            viewCount: roomData['participantCount'] ?? 0,
            isVideo: true,
            isLocked: roomData['isLocked'] ?? false,
          ),
        );
      }

      debugPrint("Processed ${liveRooms.length} active rooms in real-time.");
      // Sort the combined list
      liveRooms.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      return liveRooms;
    });
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
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(child: _buildPopularGrid()),
                      SingleChildScrollView(child: _buildFresherGrid()),
                      PartyTab(streamers: _streamers),
                      PKTab(streamers: _streamers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Builder(
      builder: (context) {
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
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        FirebaseAuth.instance.currentUser?.photoURL ?? "",
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
                        shaderCallback: (bounds) =>
                            LinearGradient(colors: [Colors.white, Colors.pink.shade200]).createShader(bounds),
                        child: Text(
                          FirebaseAuth.instance.currentUser?.displayName ?? "Unknown",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'ID: 123456789',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
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
                    final appCubit = GetIt.I<AppCubit>();
                    appCubit.logout();
                    context.go(Routes.login.path);
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildFresherGrid() {
    return Column(
      children: [
        CarouselBanner(
          imageUrls: BannerUrls.liveStreamingBanners,
          height: 120,
          autoPlayDuration: const Duration(seconds: 4),
          onBannerTap: (index) {
            // Handle banner tap
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

  Widget _buildPopularGrid() {
    return Column(
      children: [
        // Grid for your static dummy data
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
        // This StreamBuilder now correctly receives and displays live updates
        StreamBuilder<List<StreamerModel>>(
          stream: _allRoomsStream,
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
              return const SizedBox.shrink(); // Show nothing if no live rooms
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

  const StreamerModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.bio,
    required this.viewCount,
    this.isPremium = false,
    this.isVideo = true,
    this.isLocked = false,
  });
}
