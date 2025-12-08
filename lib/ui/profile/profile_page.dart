import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/auto_scroll_text.dart';
import '../../data/remote/firebase/profile_services.dart';
import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

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
                      icon: Icon(CupertinoIcons.back, size: 28, color: AppColors.pink),
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
                    IconButton(
                      icon: Icon(CupertinoIcons.pencil, size: 28, color: AppColors.pink),
                      onPressed: () {
                        context.push(Routes.editProfile.path);
                      },
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.settings, size: 28, color: AppColors.pink),
                      onPressed: () {
                        context.push(Routes.settingsPage.path);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _userId == null
                    ? Center(
                        child: Text('Please log in to see your profile.', style: TextStyle(color: Colors.white)),
                      )
                    : StreamBuilder<DocumentSnapshot>(
                        stream: ProfileService.getUserProfileStream(_userId!),
                        builder: (context, snapshot) {
                          // Handle Loading State
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: AppColors.pink));
                          }

                          // Handle Error State
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red.shade300)),
                            );
                          }

                          // Handle No Data State
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Center(
                              child: Text('Profile not found.', style: TextStyle(color: Colors.white70)),
                            );
                          }

                          // Handle Success State
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final uid = snapshot.data!.id;

                          // Map Firestore data to our local UserProfile model
                          final userProfile = UserProfile(
                            name: data['displayName'] ?? 'No Name',
                            id: uid,
                            displayId: data['displayId'] ?? 'N/A',
                            country: data['country'] ?? 'N/A',
                            countryFlagEmoji: data['countryFlagEmoji'],
                            bio: data['bio'] ?? 'No bio yet.',
                            profileImage: data['photoUrl'] ?? '',
                            followers: data['followerCount'] ?? 0,
                            following: data['followingCount'] ?? 0,
                            diamonds: data['diamonds'] ?? 0,
                            beans: data['balance'] ?? 0,
                          );

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _buildProfileSection(userProfile),
                                const SizedBox(height: 30),
                                FutureBuilder<List<SimpleUser>>(
                                  future: ProfileService.getMutualsList(userProfile.id),
                                  builder: (context, mutualsSnapshot) {
                                    if (mutualsSnapshot.connectionState == ConnectionState.waiting) {
                                      return _buildStatistics(userProfile, null); // Pass null for loading
                                    }
                                    final friendsCount = mutualsSnapshot.data?.length ?? 0;
                                    return _buildStatistics(userProfile, friendsCount);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildAchievementChips(userProfile),
                                const SizedBox(height: 30),
                                _buildButtonsGrid(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserProfile userProfile) {
    final profileImageUrl = userProfile.profileImage;

    Widget countryIndicator;
    if (userProfile.countryFlagEmoji != null && userProfile.countryFlagEmoji!.isNotEmpty) {
      countryIndicator = Text(userProfile.countryFlagEmoji!, style: const TextStyle(fontSize: 16));
    } else {
      countryIndicator = Icon(Icons.location_on_rounded, color: Colors.blue.shade300, size: 14);
    }

    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.pinkLight, AppColors.pinkDark, Colors.pink.shade400, AppColors.pink600],
            ),
            boxShadow: [
              BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
              BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 0)),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: (profileImageUrl.isNotEmpty)
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 70),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 70),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Name
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [AppColors.pinkLight, AppColors.pinkDark]).createShader(bounds),
          child: AutoScrollText(
            text: userProfile.name,
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
                'ID: ${userProfile.displayId}',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
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
                  countryIndicator, // <-- MODIFIED

                  const SizedBox(width: 4),
                  Text(
                    userProfile.country, // Updated
                    style: TextStyle(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ## NEW: BIO SECTION ##
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            userProfile.bio,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // ## END NEW SECTION ##
      ],
    );
  }

  // ## MODIFICATION: Added friendsCount and check for loading ##
  Widget _buildStatistics(UserProfile userProfile, int? friendsCount) {
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
              // Show a dash while friends count is loading
              _buildStatItem('Friends', friendsCount, Colors.cyan),
              _buildVerticalDivider(),
              _buildStatItem('Followers', userProfile.followers, Colors.pink),
              _buildVerticalDivider(),
              _buildStatItem('Following', userProfile.following, Colors.pink),
            ],
          ),
        ),
      ),
    );
  }

  // ## MODIFICATION: Handle null count for loading state ##
  Widget _buildStatItem(String label, int? count, Color color) {
    String displayCount = count == null ? '-' : _formatNumber(count);
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: [color, color]).createShader(bounds),
          child: Text(
            displayCount, // Use formatted count
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

  // ## END MODIFICATIONS ##

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

  Widget _buildAchievementChips(UserProfile userProfile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAchievementChip(
          assetIcon: 'assets/icons/beans.svg',
          count: userProfile.beans,
          // Updated
          color: Colors.amber,
          label: 'Beans',
          onTap: () {
            context.push(Routes.topUp.path);
          },
        ),
        const SizedBox(width: 16),
        _buildAchievementChip(
          icon: Icons.diamond_outlined,
          count: userProfile.diamonds, // Updated
          color: Colors.cyan,
          label: 'Diamonds',
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
      ProfileButton(
        title: 'VIP',
        icon: Icons.diamond_outlined,
        onTap: () {
          context.push(Routes.vip.path);
        },
      ),
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
      ProfileButton(
        title: 'My Invites',
        icon: Icons.group_add_rounded,
        onTap: () {
          context.push(Routes.myInvites.path);
        },
      ),
      ProfileButton(
        title: 'Profile Visitors',
        icon: Icons.visibility_rounded,
        onTap: () {
          context.push(Routes.visitors.path);
        },
      ),
      ProfileButton(
        title: 'Apply Hosting',
        icon: Icons.live_tv_rounded,
        onTap: () {
          context.push(Routes.applyHosting.path);
        },
      ),
      ProfileButton(
        title: 'Apply Agency',
        icon: Icons.business_rounded,
        onTap: () {
          context.push(Routes.applyAgency.path);
        },
      ),
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
  final String displayId;
  final String country;
  final String? countryFlagEmoji;
  final String bio;
  final String profileImage;
  final int followers;
  final int following;
  final int diamonds;
  final int beans;

  UserProfile({
    required this.name,
    required this.id,
    required this.displayId,
    required this.country,
    this.countryFlagEmoji,
    required this.bio,
    required this.profileImage,
    required this.followers,
    required this.following,
    required this.diamonds,
    required this.beans,
  });
}
