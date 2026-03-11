import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowUsPage extends StatelessWidget {
  const FollowUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Follow Us',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 28),
            _buildCommunitiesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Title text
          const Expanded(
            child: Text(
              'GS LIVE\nGlobal\nCommunity',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ),
          // Right: illustration
          Container(
            width: 200,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(80),
                bottomLeft: Radius.circular(80),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Globe background
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBBD0F0).withValues(alpha: 0.5),
                  ),
                ),
                // Illustration overlay
                const Icon(Icons.public_rounded, size: 80, color: Color(0xFF90A4AE)),
                // Heart badge
                Positioned(
                  top: 18,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 10, color: Colors.white),
                        SizedBox(width: 3),
                        Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Welcome to the GS Live Global Community! Here, you can discover the most exciting premium content and connect with social enthusiasts from around the world to share the latest market insights. Join the groups below now and start your global social journey!',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF555555),
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildCommunitiesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommended Communities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCommunityCard(
                  icon: Icons.facebook_rounded,
                  iconColor: const Color(0xFF1877F2),
                  iconBg: Colors.white,
                  label: 'Facebook',
                  onTap: () => launchUrl(Uri.parse('https://facebook.com')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCommunityCard(
                  icon: Icons.smart_display_rounded,
                  iconColor: Colors.red,
                  iconBg: Colors.white,
                  label: 'YouTube',
                  onTap: () => launchUrl(Uri.parse('https://youtube.com')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: iconColor.withValues(alpha: 0.15), blurRadius: 8),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
