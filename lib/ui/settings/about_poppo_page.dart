import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutPoppoPage extends StatelessWidget {
  const AboutPoppoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'About GS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 50),
          // Logo Section
          Center(
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 12),
                Text(
                  'GS LIVE 5.4.522.0127',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Agreements List
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem('Privacy Policy'),
                _buildMenuItem('Terms Of Service'),
                _buildMenuItem('Live Agreement'),
                _buildMenuItem('User Recharge Agreement'),
                _buildMenuItem('No Child Endangerment Policy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const SweepGradient(
          colors: [
            Color(0xFF00D1FF), // Blue
            Color(0xFFFF00D6), // Pink
            Color(0xFFFFF500), // Yellow
            Color(0xFF42FF00), // Green
            Color(0xFF00D1FF),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: const Text(
            'po.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return Column(
      children: [
        ListTile(
          onTap: () {},
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.black.withValues(alpha: 0.2),
            size: 24,
          ),
        ),
        const Divider(height: 1, indent: 20, color: Color(0xFFF5F5F9)),
      ],
    );
  }
}
