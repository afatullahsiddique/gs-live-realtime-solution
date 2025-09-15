import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

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
    beans: 12680,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
        _buildAchievementChip(
          assetIcon: 'assets/icons/beans.svg',
          count: _userProfile.beans,
          color: Colors.amber,
          label: 'Beans',
          onTap: () {
            context.push(Routes.topUp.path);
          },
        ),
      ],
    );
  }

  Widget _buildAchievementChip({
    IconData? icon,
    String? assetIcon,
    required int count,
    required Color color,
    required String label,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                if (icon != null) Icon(icon, color: color, size: 24),
                if (assetIcon != null) SvgPicture.asset(assetIcon, color: color, width: 24),
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
      ),
    );
  }

  Widget _buildButtonsGrid() {
    final buttons = [
      ProfileButton(
        title: 'Top Up',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () {
          context.push(Routes.topUp.path);
        },
      ),
      ProfileButton(
        title: 'Earnings',
        icon: Icons.trending_up_rounded,
        onTap: () {
          context.push(Routes.earnings.path);
        },
      ),
      ProfileButton(title: 'VIP', icon: Icons.diamond_rounded),
      ProfileButton(
        title: 'Store',
        icon: Icons.shopping_bag_rounded,
        onTap: () {
          context.push(Routes.store.path);
        },
      ),
      ProfileButton(
        title: 'My Bag',
        icon: Icons.shopping_basket_rounded,
        onTap: () {
          context.push(Routes.myBag.path);
        },
      ),
      ProfileButton(
        title: 'My Level',
        icon: Icons.military_tech_rounded,
        onTap: () {
          context.push(Routes.myLevel.path);
        },
      ),
      ProfileButton(
        title: 'Support',
        icon: Icons.support_agent_rounded,
        onTap: () {
          context.push(Routes.feedback.path);
        },
      ),
      ProfileButton(title: 'Blocked', icon: Icons.block_rounded),
      ProfileButton(title: 'My Invites', icon: Icons.group_add_rounded),
      ProfileButton(title: 'Profile Visitors', icon: Icons.visibility_rounded),
      ProfileButton(title: 'Apply Hosting', icon: Icons.live_tv_rounded),
      ProfileButton(title: 'Apply Agency', icon: Icons.business_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final button = buttons[index];
        return button;
      },
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

class ProfileButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const ProfileButton({Key? key, required this.title, required this.icon, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            debugPrint('$title tapped');
          },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF5E4710), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFCA9B34), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
  final int beans;

  UserProfile({
    required this.name,
    required this.id,
    required this.country,
    required this.profileImage,
    required this.friends,
    required this.followers,
    required this.following,
    required this.diamonds,
    required this.beans,
  });
}
