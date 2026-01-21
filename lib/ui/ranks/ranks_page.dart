import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class RanksPage extends StatefulWidget {
  const RanksPage({super.key});

  @override
  State<RanksPage> createState() => _RanksPageState();
}

class _RanksPageState extends State<RanksPage> with TickerProviderStateMixin {
  late TabController _categoryController;
  late TabController _periodController;

  // Dummy data
  final List<RankUser> _dummyUsers = [
    RankUser(
      rank: 1,
      name: 'Sakib Rahman',
      id: '100004',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      coins: 125400,
    ),
    RankUser(
      rank: 2,
      name: 'Tasnim Ahmed',
      id: '100029',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      coins: 98750,
    ),
    RankUser(
      rank: 3,
      name: 'Nusrat Jahan',
      id: '100023',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      coins: 87300,
    ),
    RankUser(
      rank: 4,
      name: 'Abdullah Sifat',
      id: '100004',
      imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
      coins: 108100,
    ),
    RankUser(
      rank: 5,
      name: 'Mehedi Hasan',
      id: '100029',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      coins: 46500,
    ),
    RankUser(
      rank: 6,
      name: 'Samiul Islam',
      id: '100023',
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      coins: 11000,
    ),
    RankUser(
      rank: 7,
      name: 'Tanvir Hossain',
      id: '100012',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      coins: 9800,
    ),
    RankUser(
      rank: 8,
      name: 'Ayesha Siddika',
      id: '100045',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      coins: 8650,
    ),
    RankUser(
      rank: 9,
      name: 'Fahim Khan',
      id: '100067',
      imageUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=400',
      coins: 7200,
    ),
    RankUser(
      rank: 10,
      name: 'Lamia Akter',
      id: '100088',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      coins: 6450,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TabController(length: 2, vsync: this);
    _periodController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a0a1e), Color(0xFF2d1b2b), Color(0xFF1a0a1e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildCategoryTabs(),
              const SizedBox(height: 10),
              _buildPeriodTabs(),
              Expanded(
                child: TabBarView(
                  controller: _periodController,
                  children: [_buildRankContent(), _buildRankContent(), _buildRankContent()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Ranks',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
      ),
      child: TabBar(
        controller: _categoryController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF1168), Color(0xFFD81B60)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: const [
          Tab(text: 'Agency'),
          Tab(text: 'Host')
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
      ),
      child: TabBar(
        controller: _periodController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF1168), Color(0xFFD81B60)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Weeks'),
          Tab(text: 'Month'),
        ],
      ),
    );
  }

  Widget _buildRankContent() {
    final topThree = _dummyUsers.take(3).toList();
    final restUsers = _dummyUsers.skip(3).take(7).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildPodium(topThree),
          const SizedBox(height: 30),
          _buildRankList(restUsers),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPodium(List<RankUser> topThree) {
    if (topThree.length < 3) return const SizedBox();

    return Container(
      height: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Podium platforms
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place platform
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey.shade400.withOpacity(0.6), Colors.grey.shade600.withOpacity(0.4)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 1st place platform
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.amber.shade400.withOpacity(0.8), Colors.amber.shade700.withOpacity(0.6)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.amber.shade200, width: 1),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 3rd place platform
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.orange.shade400.withOpacity(0.6), Colors.orange.shade700.withOpacity(0.4)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Winners on podium
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _buildPodiumUser(topThree[1], 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 55),
                    child: _buildPodiumUser(topThree[0], 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildPodiumUser(topThree[2], 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(RankUser user, int position) {
    final isFirst = position == 1;
    final avatarSize = isFirst ? 90.0 : 70.0;

    Color borderColor;
    if (position == 1) {
      borderColor = Colors.amber.shade400;
    } else if (position == 2) {
      borderColor = Colors.grey.shade400;
    } else {
      borderColor = Colors.orange.shade400;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [borderColor, borderColor.withOpacity(0.6)]),
            boxShadow: [BoxShadow(color: borderColor.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)],
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: Image.network(
              user.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.person, color: Colors.white, size: 40),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.name,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text('ID: ${user.id}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
              const SizedBox(width: 3),
              Text(
                _formatCoins(user.coins),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildRankList(List<RankUser> users) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              return _buildRankListItem(users[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRankListItem(RankUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
              border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                '${user.rank}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Profile picture
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.network(
                user.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.person, color: Colors.white, size: 25),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name and ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('ID: ${user.id}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Coins
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade400.withOpacity(0.6), Colors.pink.shade600.withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                const SizedBox(width: 3),
                Text(
                  _formatCoins(user.coins),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    } else {
      return coins.toString();
    }
  }
}

// Data Model
class RankUser {
  final int rank;
  final String name;
  final String id;
  final String imageUrl;
  final int coins;

  RankUser({required this.rank, required this.name, required this.id, required this.imageUrl, required this.coins});
}
