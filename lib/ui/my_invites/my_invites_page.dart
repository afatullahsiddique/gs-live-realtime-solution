import 'package:flutter/material.dart';

class MyInvitesPage extends StatefulWidget {
  const MyInvitesPage({super.key});

  @override
  State<MyInvitesPage> createState() => _MyInvitesPageState();
}

class _MyInvitesPageState extends State<MyInvitesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String referralCode = "LUNA123"; // Dummy referral code
  final List<Map<String, dynamic>> invitedFriends = [
    {"name": "Alice Kim", "status": "Joined"},
    {"name": "John Park", "status": "Pending"},
    {"name": "Sakura Lee", "status": "Joined"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECD2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Gradient Section with Header and Banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF5722), Color(0xFFFFAB40)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Custom Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Invitation Bonus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    // Moving Text Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Congratulations! Vai🦋🦋Claimed \$ 0.1 , earned \$ 702.4',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Illustration Area (Placeholder for coins/gifts)
                    const SizedBox(height: 100, child: Center(child: Icon(Icons.stars_rounded, color: Colors.white70, size: 80))),
                  ],
                ),
              ),
            ),

            // Main Invitation Card
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFFF8A65), width: 4),
                ),
                child: Column(
                  children: [
                    const Text('Invite someone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 16),
                    const Text('Can earn up to', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF8D6E63))),
                    const SizedBox(height: 4),
                    const Text('\$25.6', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFF5252))),
                    const SizedBox(height: 16),
                    const Text(
                      'The more you invite, the more rewards you will get',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    const SizedBox(height: 24),
                    // Invite Now Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFFFAB40)],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7043).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Invite Now',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('My ID: $referralCode', style: const TextStyle(fontSize: 13, color: Color(0xFFFF8A65))),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFFF8A65)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Controls and Summary
            Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                children: [
                  _buildCustomTabBar(),
                  _buildRewardsSummary(),
                  _buildInviteFriendsBanner(),
                  _buildInvitationsList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC80).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFFFF7043),
        unselectedLabelColor: Colors.white,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'My rewards'),
          Tab(text: 'Income Rank'),
        ],
      ),
    );
  }

  Widget _buildRewardsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem('0', 'Claimed Rewards', Icons.monetization_on_rounded, const Color(0xFFFF80AB)),
              Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
              _buildSummaryItem('0', 'Number of invitees', null, const Color(0xFF666666)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Available for today', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
              const SizedBox(width: 4),
              const Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFFFF80AB)),
              const SizedBox(width: 4),
              const Text('0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Receive', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData? icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteFriendsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
        ),
      ),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Invite Friends',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.shopping_bag_rounded, size: 90, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF333333)),
                  SizedBox(width: 4),
                  Text('My Code', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('Invitations from last 7 days (0)', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              Spacer(),
              Text('More', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFBBBBBB)),
            ],
          ),
          const SizedBox(height: 40),
          // Empty State Illustration
          const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 12),
          const Text('No more data', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
