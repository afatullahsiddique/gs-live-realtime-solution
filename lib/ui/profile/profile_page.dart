import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dummy profile data
  final UserProfile _userProfile = UserProfile(
    name: 'Luna Park',
    id: '123456789',
    country: 'South Korea',
    profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    friends: 2847,
    followers: 15420,
    following: 892,
    diamonds: 23750,
    stars: 12680,
  );

  final List<ProfileButton> _profileButtons = [
    ProfileButton(
      title: 'Top Up',
      icon: Icons.account_balance_wallet_rounded,
      color: Colors.green,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF45a049)],
    ),
    ProfileButton(
      title: 'Earnings',
      icon: Icons.trending_up_rounded,
      color: Colors.amber,
      gradientColors: [Color(0xFFFFB300), Color(0xFFFFA000)],
    ),
    ProfileButton(
      title: 'VIP',
      icon: Icons.diamond_rounded,
      color: Colors.purple,
      gradientColors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      isPremium: true,
    ),
    ProfileButton(
      title: 'Store',
      icon: Icons.shopping_bag_rounded,
      color: Colors.blue,
      gradientColors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    ),
    ProfileButton(
      title: 'My Bag',
      icon: Icons.shopping_basket_rounded,
      color: Colors.indigo,
      gradientColors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
    ),
    ProfileButton(
      title: 'My Level',
      icon: Icons.military_tech_rounded,
      color: Colors.orange,
      gradientColors: [Color(0xFFFF9800), Color(0xFFF57400)],
    ),
    ProfileButton(
      title: 'Support',
      icon: Icons.support_agent_rounded,
      color: Colors.teal,
      gradientColors: [Color(0xFF009688), Color(0xFF00796B)],
    ),
    ProfileButton(
      title: 'Blocked',
      icon: Icons.block_rounded,
      color: Colors.red,
      gradientColors: [Color(0xFFF44336), Color(0xFFD32F2F)],
    ),
    ProfileButton(
      title: 'My Invites',
      icon: Icons.group_add_rounded,
      color: Colors.cyan,
      gradientColors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
    ),
    ProfileButton(
      title: 'Profile Visitors',
      icon: Icons.visibility_rounded,
      color: Colors.pink,
      gradientColors: [Color(0xFFE91E63), Color(0xFFC2185B)],
    ),
    ProfileButton(
      title: 'Apply Hosting',
      icon: Icons.live_tv_rounded,
      color: Colors.deepPurple,
      gradientColors: [Color(0xFF673AB7), Color(0xFF512DA8)],
      isPremium: true,
    ),
    ProfileButton(
      title: 'Apply Agency',
      icon: Icons.business_rounded,
      color: Colors.brown,
      gradientColors: [Color(0xFF795548), Color(0xFF5D4037)],
      isPremium: true,
    ),
  ];

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
              // Header Section
              Padding(
                padding: EdgeInsets.only(left: 0, right: 20, top: 0, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 2))],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildProfileSection(),
                      const SizedBox(height: 30),
                      _buildStatistics(),
                      const SizedBox(height: 20),
                      _buildAchievementChips(),
                      const SizedBox(height: 30),
                      _buildButtonsGrid(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Large Profile Picture
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade300, Colors.pink.shade500, Colors.purple.shade400, Colors.pink.shade600],
            ),
            boxShadow: [
              BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
              BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 0)),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.network(
              _userProfile.profileImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 70),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Name
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500]).createShader(bounds),
          child: Text(
            _userProfile.name,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 8),

        // ID and Country
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
              ),
              child: Text(
                'ID: ${_userProfile.id}',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.blue.shade300, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _userProfile.country,
                    style: TextStyle(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Friends', _userProfile.friends, Colors.cyan),
              _buildVerticalDivider(),
              _buildStatItem('Followers', _userProfile.followers, Colors.pink),
              _buildVerticalDivider(),
              _buildStatItem('Following', _userProfile.following, Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: [color, color]).createShader(bounds),
          child: Text(
            _formatNumber(count),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildAchievementChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAchievementChip(
          icon: Icons.diamond_rounded,
          count: _userProfile.diamonds,
          color: Colors.cyan,
          label: 'Diamonds',
        ),
        const SizedBox(width: 16),
        _buildAchievementChip(icon: Icons.star_rounded, count: _userProfile.stars, color: Colors.amber, label: 'Stars'),
      ],
    );
  }

  Widget _buildAchievementChip({
    required IconData icon,
    required int count,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatNumber(count),
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _profileButtons.length,
      itemBuilder: (context, index) {
        return _buildProfileButton(_profileButtons[index]);
      },
    );
  }

  Widget _buildProfileButton(ProfileButton button) {
    return GestureDetector(
      onTap: () {
        // Handle button tap
        print('${button.title} tapped');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: button.color.withOpacity(0.9),
          boxShadow: [
            BoxShadow(color: button.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            if (button.isPremium)
              BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 0)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: button.color),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(button.icon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    button.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

// Data Models
class UserProfile {
  final String name;
  final String id;
  final String country;
  final String profileImage;
  final int friends;
  final int followers;
  final int following;
  final int diamonds;
  final int stars;

  UserProfile({
    required this.name,
    required this.id,
    required this.country,
    required this.profileImage,
    required this.friends,
    required this.followers,
    required this.following,
    required this.diamonds,
    required this.stars,
  });
}

class ProfileButton {
  final String title;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final bool isPremium;

  ProfileButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.gradientColors,
    this.isPremium = false,
  });
}
