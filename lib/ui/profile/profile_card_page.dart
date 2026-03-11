import 'package:cute_live/ui/profile/edit_profile_page.dart';
import 'package:cute_live/ui/profile/repository/user_repository.dart';
import 'package:cute_live/ui/profile/model/user_profile_model.dart';
import 'package:flutter/material.dart';

class ProfileCardPage extends StatefulWidget {
  const ProfileCardPage({super.key});

  @override
  State<ProfileCardPage> createState() => _ProfileCardPageState();
}

class _ProfileCardPageState extends State<ProfileCardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  bool _isFetching = true;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isFetching = true);
    try {
      final user = await UserRepository().getUserProfile();
      setState(() {
        _user = user;
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.black87, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                title: Text(
                  _user?.host?.displayName ?? _user?.name ?? 'Loading...',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded,
                        color: Colors.black87, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Colors.black87, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      );

                    },
                  ),
                ],
                expandedHeight: 0,
              ),
              SliverToBoxAdapter(child: _buildProfileHeader()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Colors.black,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [
                      Tab(text: 'Data'),
                      Tab(text: 'Honor Wall'),
                    ],
                  ),
                ),
              ),
            ],
            body: _isFetching
                ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDataTab(),
                      _buildHonorWallTab(),
                    ],
                  ),
          ),
          // Floating camera button
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Photo
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image area (Slider)
            Container(
              height: 280, // Adjusted to a more standard height
              width: double.infinity,
              color: const Color(0xFFF0F0F0),
              child: (_user?.photoUrls != null && _user!.photoUrls!.isNotEmpty)
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: _user!.photoUrls!.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPhotoIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _user!.photoUrls![index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        // Indicator
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _user!.photoUrls!.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(
                                      _currentPhotoIndex == entry.key ? 0.9 : 0.4),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.photo_library_outlined,
                          size: 50, color: Color(0xFFD0D0D0))),
            ),
            // Rank badge top-right
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFE65100)],
                  ),
                ),
                child: const Center(
                  child: Text('00',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
            // Online badge bottom-right
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
            // Avatar overlapping cover
            Positioned(
              bottom: -30,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFD9D9D9),
                  backgroundImage: _user?.photoUrl != null
                      ? NetworkImage(_user!.photoUrl!)
                      : null,
                  child: _user?.photoUrl == null
                      ? const Icon(Icons.person, size: 34, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Username
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_user?.host?.displayName ?? _user?.name ?? '',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        const SizedBox(height: 6),
        // Badges row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Country flag
              Text(_user?.host?.countryFlagEmoji ?? '�', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              // VIP badge placeholder
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1565C0)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('d·18',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('ID:${_user?.host?.displayId ?? ''}',
                  style:
                      const TextStyle(color: Color(0xFF666666), fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.copy_rounded, size: 13, color: Color(0xFFAAAAAA)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Following ', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
              Text(_user?.host?.followingCount.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 16),
              const Text('Followers ', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
              Text(_user?.host?.followerCount.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelCards(),
          const SizedBox(height: 16),
          _buildGiftGalleryCard(),
          const SizedBox(height: 16),
          _buildContributionCard(),
          const SizedBox(height: 24),
          _buildPersonalInfo(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLevelCards() {
    return Row(
      children: [
        Expanded(child: _buildLevelChip('▲ 1', 'Wealth Level', const Color(0xFF4CAF50))),
        const SizedBox(width: 10),
        Expanded(child: _buildLevelChip('◆ 1', 'Livestream Level', const Color(0xFF4CAF50))),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text('Fans', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Fan Club (0)', style: TextStyle(color: Color(0xFFE91E63), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(String badge, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badge,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGiftGalleryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gift Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Lit: 0/16',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          // Gift placeholder icons
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.card_giftcard_rounded, size: 20, color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }

  Widget _buildContributionCard() {
    // Three medal/rank badge placeholder colors
    final badgeColors = [Colors.orangeAccent, Colors.lightBlueAccent, Colors.pinkAccent];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contribution List',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C3AED))),
                const SizedBox(height: 2),
                Text('Participants on rank: 0',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: badgeColors.map((c) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                ),
                child: Icon(Icons.workspace_premium_rounded, size: 18, color: c),
              ),
            )).toList(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _user?.host?.bio ?? 'She/He was lazy and left nothing behind.',
          style: TextStyle(
              color: Colors.black.withValues(alpha: 0.45), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildHonorWallTab() {
    return const Center(
      child: Text('Honor Wall coming soon',
          style: TextStyle(color: Colors.black38, fontSize: 14)),
    );
  }
}

// Sticky TabBar delegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
