import 'package:flutter/material.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Reward',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTaskEarningsCard(),
          _buildPromotionalBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const Center(child: Text('Regular Tasks')),
                _buildActivityList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskEarningsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Task Earnings",
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEarningItem('0', const Color(0xFFFF80AB)),
              const SizedBox(width: 40),
              _buildEarningItem('0', const Color(0xFFFFD54F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String value, Color iconColor) {
    return Row(
      children: [
        Icon(Icons.monetization_on_rounded, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFFBA68C8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'লাইভ টাস্ক লেভেলের বিস্তারিত\nবিস্তারিত এখানে ক্লিক করুন',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Icon(Icons.square_rounded, size: 20, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(Icons.play_arrow_rounded, size: 24, color: Colors.pinkAccent.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorPadding: const EdgeInsets.only(top: 40),
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelColor: Colors.black,
        unselectedLabelColor: Color(0xFF999999),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        tabs: const [
          Tab(text: 'Regular'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVIPRewardItem(),
        const SizedBox(height: 16),
        _buildInviteTreeSection(),
        _buildTaskItem(
          icon: Icons.stars_rounded,
          title: 'Check in for 1 day during the Ramadan event.',
          subtitle: '(0/25)',
          details: 'Claim 2 live boxes daily for a valid check-in.',
          reward: '+1d',
          rewardIcon: Icons.calendar_today_rounded,
          rewardColor: Color(0xFFFF80AB),
        ),
        _buildTaskItem(
          icon: Icons.card_giftcard_rounded,
          title: 'Watch the live for 300 seconds',
          subtitle: '(0/300, 0/1)',
          reward: '+40',
          rewardIcon: Icons.monetization_on_rounded,
          rewardColor: Color(0xFFFFD54F),
        ),
        _buildHashtagLevelItem('#Pet Love', '+30,000', Color(0xFFFF80AB)),
        _buildHashtagLevelItem('#dailytopic', '+45,000', Color(0xFFFF80AB)),
      ],
    );
  }

  Widget _buildVIPRewardItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VIP daily rewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('VIP', style: TextStyle(color: Color(0xFF9C27B0), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFFFD54F)),
                    const SizedBox(width: 4),
                    const Text('+35,000', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF9800)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('VIP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTreeSection() {
    return Column(
      children: [
        Row(
          children: [
            _buildSmallIcon(Icons.email_outlined, Color(0xFFFF7043)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Every invite gives you a chance to win \$27.75',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const Text('Hide', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
            const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: Color(0xFF666666)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 60),
            _buildRewardTag('+21,500', Color(0xFFFFD54F)),
            const SizedBox(width: 8),
            _buildRewardTag('+256,000', Color(0xFFFF80AB)),
          ],
        ),
        _buildTimelineItem(
          'Invite users to download and stay active for a chance to win 21500 coins.',
          '+21,500',
          Color(0xFFFFD54F),
        ),
        _buildTimelineItem(
          'Invite a female user to go live and earn 256000 points.',
          '+256,000',
          Color(0xFFFF80AB),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String text, String reward, Color rewardColor, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 23),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xFFE0E0E0),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF7E57C2), shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black)),
                          const SizedBox(height: 8),
                          _buildRewardTag(reward, rewardColor, small: true),
                        ],
                      ),
                    ),
                    _buildGoButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? details,
    required String reward,
    required IconData rewardIcon,
    required Color rewardColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallIcon(icon, Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
                  ],
                ),
                if (details != null) ...[
                  const SizedBox(height: 4),
                  Text(details, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(rewardIcon, size: 14, color: rewardColor),
                    const SizedBox(width: 4),
                    Text(reward, style: TextStyle(fontSize: 12, color: Colors.black)),
                  ],
                ),
              ],
            ),
          ),
          _buildGoButton(),
        ],
      ),
    );
  }

  Widget _buildHashtagLevelItem(String hashtag, String reward, Color rewardColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildSmallIcon(Icons.video_library_rounded, Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hashtag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_rounded, size: 14, color: rewardColor),
                        const SizedBox(width: 4),
                        Text(reward, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Text('Hide', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: Color(0xFF666666)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 1, height: 20, color: const Color(0xFFE0E0E0)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF7E57C2), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Video selected as a "High Quality" or "Recommend" video (0/1)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          _buildGoButton(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRewardTag(reward, rewardColor, small: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIcon(IconData icon, Color bgColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: bgColor, size: 24),
    );
  }

  Widget _buildRewardTag(String value, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, size: small ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: small ? 10 : 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGoButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'GO >',
        style: TextStyle(color: Color(0xFF7E57C2), fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
