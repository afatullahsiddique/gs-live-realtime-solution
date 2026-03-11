import 'package:flutter/material.dart';

class GuardianPage extends StatefulWidget {
  const GuardianPage({super.key});

  @override
  State<GuardianPage> createState() => _GuardianPageState();
}

class _GuardianPageState extends State<GuardianPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedDurationIndex = 0; // 0: 1 Month, 1: 3 Months, 2: 6 Months, 3: 12 Months

  final List<String> _durations = ['1 Month', '3 Months', '6 Months', '12 Months'];
  final List<int> _silverPrices = [150000, 450000, 900000, 1800000];
  final List<int> _kingPrices = [1500000, 4500000, 9000000, 18000000];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Open Guardian',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildThemedPage(
            themeColor: const Color(0xFF1565C0), // Silver Blue
            emblemIcon: Icons.shield_rounded,
            guardianName: 'Silver Guardian',
            prices: _silverPrices,
            accentColor: const Color(0xFF64B5F6),
          ),
          _buildThemedPage(
            themeColor: const Color(0xFF4A148C), // King Purple
            emblemIcon: Icons.workspace_premium_rounded,
            guardianName: 'King Guardian',
            prices: _kingPrices,
            accentColor: const Color(0xFFBA68C8),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedPage({
    required Color themeColor,
    required IconData emblemIcon,
    required String guardianName,
    required List<int> prices,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withValues(alpha: 0.8), const Color(0xFF0D1B2A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Emblem Section
              _buildEmblemSection(emblemIcon, accentColor, guardianName),
              const SizedBox(height: 32),
              // Main Actions Section
              _buildActionsSection(prices, accentColor, guardianName),
              // Menu Items
              _buildMenuSection(),
              // Privileges Section
              _buildPrivilegesSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmblemSection(IconData icon, Color accentColor, String name) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        Column(
          children: [
            Icon(icon, size: 180, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        // Swipe Arrows
        Positioned(
          left: 20,
          child: _currentPage == 1
              ? Icon(Icons.double_arrow_rounded, color: Colors.white.withValues(alpha: 0.3), size: 32)
              : const SizedBox.shrink(),
        ),
        Positioned(
          right: 20,
          child: _currentPage == 0
              ? Icon(Icons.double_arrow_rounded, color: Colors.white.withValues(alpha: 0.3), size: 32)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActionsSection(List<int> prices, Color accentColor, String guardianName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'I want to guard him/her',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildSmallIconButton(Icons.chair_alt_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Select', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 16),
          // Duration Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) => _buildDurationPill(index, accentColor)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Coins needed: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 4),
              Text(
                '${prices[_selectedDurationIndex]}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPill(int index, Color accentColor) {
    bool isSelected = _selectedDurationIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDurationIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          _durations[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem('My guardian'),
          const Divider(height: 1, color: Colors.white12),
          _buildMenuItem('Guard me'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: () {},
    );
  }

  Widget _buildPrivilegesSection() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 30, child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Guardian privileges', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              SizedBox(width: 30, child: Divider(color: Colors.white24)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildPrivilegeBox(Icons.trending_up_rounded, 'Higher Rank'),
              _buildPrivilegeBox(Icons.verified_rounded, 'Distinguished Logo'),
              _buildPrivilegeBox(Icons.login_rounded, 'Special Entry Effect'),
              _buildPrivilegeBox(Icons.chat_bubble_rounded, 'Exclusive Bubbles'),
              _buildPrivilegeBox(Icons.card_giftcard_rounded, 'Privileged Gifts'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildPrivilegeBox(IconData icon, String label) {
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 3,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    Color btnColor = _currentPage == 0 ? const Color(0xFF2979FF) : const Color(0xFF9C27B0);
    String guardianType = _currentPage == 0 ? 'Silver Guardian' : 'King Guardian';

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: btnColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: btnColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Center(
        child: Text(
          'Activated $guardianType',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
