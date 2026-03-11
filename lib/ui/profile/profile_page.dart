import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_state.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Me',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 26, color: Color(0xFF333333)),
                    onPressed: () => context.push(Routes.qrScanner.path),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26, color: Color(0xFF333333)),
                    onPressed: () {
                      context.push(Routes.settingsPage.path);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pink));
                  }

                  if (state is ProfileError) {
                    return Center(child: Text(state.message, style: TextStyle(color: Colors.red.shade300)));
                  }

                  if (state is ProfileLoaded) {
                    final user = state.user;
                    final userProfile = UserProfile(
                      name: user.name ?? '',
                      id: user.id,
                      displayId: user.host?.displayId ?? '',
                      country: user.host?.country ?? '',
                      countryFlagEmoji: user.host?.countryFlagEmoji ?? '',
                      bio: user.host?.bio ?? '',
                      profileImage: user.photoUrl ?? '',
                      followers: user.host?.followerCount ?? 0,
                      following: user.host?.followingCount ?? 0,
                      diamonds: user.host?.diamonds ?? 0,
                      beans: user.host?.balance ?? 0,
                    );

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildProfileHeader(userProfile),
                          _buildCompletionBanner(),
                          _buildStatisticsRow(userProfile),
                          _buildWalletSection(userProfile),
                          _buildVIPGridCard(userProfile),
                          _buildPromotionalBanner(),
                          _buildStreamerCenterTile(),
                          _buildSettingsList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile userProfile) {
    return GestureDetector(
      onTap: () => context.push(Routes.profileCard.path),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: userProfile.profileImage.isNotEmpty
                    ? Image.network(userProfile.profileImage, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFD9D9D9),
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        userProfile.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // VIP Badge placeholder
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFB8C1D1), Color(0xFF8E99AF)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLevelTag('Lvl 1', const Color(0xFF8BC34A)),
                      const SizedBox(width: 6),
                      _buildLevelTag('S 1', const Color(0xFFCDDC39)),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${userProfile.displayId}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFBBBBBB)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFFF4D6D), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Your profile currently is 60% completed, polish up and making friends easier.',
              style: TextStyle(color: Color(0xFFFF4D6D), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(UserProfile userProfile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('0', 'Friends'),
          _buildStat(userProfile.following.toString(), 'Following'),
          _buildStat(userProfile.followers.toString(), 'Followers'),
          _buildStat('0', 'Visitors'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildWalletSection(UserProfile userProfile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Coins
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(Routes.topUp.path),
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9E6), Color(0xFFFFECB3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Coins', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          Text(userProfile.beans.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                        ],
                      ),
                    ),
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 40),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Points
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(Routes.topUp.path),
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF0F7), Color(0xFFFFD1E1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Points', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          Text(userProfile.diamonds.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                        ],
                      ),
                    ),
                    const Icon(Icons.circle, color: Color(0xFFFF85B0), size: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVIPGridCard(UserProfile userProfile) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFF333333), size: 24),
                const SizedBox(width: 8),
                const Text('VIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Get VIP & Enjoy Privileges', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const Spacer(),
                const Text('View', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFBBBBBB)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildVIPItem(Icons.card_giftcard_rounded, 'Reward', const Color(0xFFFF7043), onTap: () => context.push(Routes.reward.path)),
              _buildVIPItem(Icons.emoji_events_rounded, 'Rank', const Color(0xFFFFA726), onTap: () => context.push(Routes.ranks.path)),
              _buildVIPItem(Icons.local_mall_rounded, 'Store', const Color(0xFF26C6DA), onTap: () => context.push(Routes.mall.path)),
              _buildVIPItem(Icons.account_balance_wallet_rounded, 'Invite', const Color(0xFFFF5252), onTap: () => context.push(Routes.myInvites.path)),
              _buildVIPItem(Icons.security_rounded, 'Guardian', const Color(0xFF26A69A), onTap: () => context.push(Routes.guardian.path)),
              _buildVIPItem(Icons.favorite_rounded, 'Fan Club', const Color(0xFFEC407A), onTap: () => context.push(Routes.fanClub.path)),
              _buildVIPItem(Icons.stars_rounded, 'Medal Wall', const Color(0xFFFF7043), onTap: () => context.push(Routes.medalWall.path)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVIPItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'STOP',
        style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
      ),
    );
  }

  // ## END MODIFICATIONS ##

  Widget _buildStreamerCenterTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () => context.push(Routes.streamerCenter.path),
        leading: const Icon(Icons.live_tv_rounded, color: Color(0xFF666666)),
        title: const Text('Streamer Center', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(Icons.headset_mic_rounded, 'Help', trailing: '24', onTap: () => context.push(Routes.help.path)),
          _buildListTile(Icons.person_outline_rounded, 'My Agency', onTap: () => context.push(Routes.myAgency.path)),
          _buildListTile(Icons.storefront_rounded, 'Store', onTap: () => context.push(Routes.mall.path)),
          _buildListTile(Icons.workspace_premium_outlined, 'Level', onTap: () => context.push(Routes.level.path)),
          _buildListTile(Icons.military_tech_outlined, 'Medal Wall', onTap: () => context.push(Routes.medalWall.path)),
          _buildListTile(Icons.backpack_outlined, 'Backpack', onTap: () => context.push(Routes.backpack.path)),
          _buildListTile(Icons.shield_outlined, 'Guardian', onTap: () => context.push(Routes.guardian.path)),
          _buildListTile(Icons.verified_user_outlined, 'Auth', onTap: () => context.push(Routes.auth.path)),
          _buildListTile(Icons.favorite_outline_rounded, 'Follow Us', onTap: () => context.push(Routes.followUs.path)),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF666666)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
        ],
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
