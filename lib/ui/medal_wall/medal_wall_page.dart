import 'package:flutter/material.dart';

class MedalWallPage extends StatefulWidget {
  const MedalWallPage({super.key});

  @override
  State<MedalWallPage> createState() => _MedalWallPageState();
}

class _MedalWallPageState extends State<MedalWallPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A120B), // Dark gold/black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Medal Wall',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserProfileCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Achievement Medal'),
            _buildAchievementGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader('Event Medal'),
            _buildEventMedalSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD4AF37).withValues(alpha: 0.3), const Color(0xFF1A120B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=dev'), // Placeholder
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Develope...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Obtain: 0',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: const Text(
              'Level: 0',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Ornate divider simulation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOrnateLine(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFFFDECD2), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              _buildOrnateLine(rotate: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrnateLine({bool rotate = false}) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, const Color(0xFFD4AF37)],
              begin: rotate ? Alignment.centerRight : Alignment.centerLeft,
              end: rotate ? Alignment.centerLeft : Alignment.centerRight,
            ),
          ),
        ),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid() {
    final medals = [
      {'name': 'Wealth Lv.5', 'icon': Icons.diamond_rounded},
      {'name': 'Livestream Lv.5', 'icon': Icons.stars_rounded},
      {'name': 'Live Star Lv.1', 'icon': Icons.videocam_rounded},
      {'name': 'Random PK Victor Lv.1', 'icon': Icons.bolt_rounded},
      {'name': 'Fan Power Lv.1', 'icon': Icons.favorite_rounded},
      {'name': 'Active Star Lv.1', 'icon': Icons.timer_rounded},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: medals.length,
      itemBuilder: (context, index) {
        return _buildMedalCard(medals[index]['name'] as String, medals[index]['icon'] as IconData);
      },
    );
  }

  Widget _buildMedalCard(String name, IconData icon) {
    return GestureDetector(
      onTap: () => _showMedalDetail(name, icon),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A1F16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFDECD2), fontSize: 10, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMedalSection() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_rounded, size: 60, color: Colors.white.withValues(alpha: 0.1)),
          ),
          const SizedBox(height: 16),
          Text(
            'No medals earned yet',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showMedalDetail(String name, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MedalDetailSheet(name: name, icon: icon),
    );
  }
}

class _MedalDetailSheet extends StatelessWidget {
  final String name;
  final IconData icon;

  const _MedalDetailSheet({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 40),
          // Medal Large View
          _buildLargeMedal(),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Wealth level reaches Lv.5', // Placeholder
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          ),
          const Spacer(),
          // Percent bar simulation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '99.99% of users have got this',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLargeMedal() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 80),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFDD835), Color(0xFFFBC02D)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFBC02D).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: const Center(
        child: Text(
          'Go to get',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
