import 'package:flutter/material.dart';

class MallRankingPage extends StatefulWidget {
  const MallRankingPage({super.key});

  @override
  State<MallRankingPage> createState() => _MallRankingPageState();
}

class _MallRankingPageState extends State<MallRankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Store',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildKingCard(),
                _buildTabs(),
                _buildLeaderboard(),
                const SizedBox(height: 100), // Space for close button
              ],
            ),
          ),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildKingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD1C4E9), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Banner
          Positioned(
            top: -20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'APACHE KING',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              children: [
                // Avatar with crown
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.purple[100],
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const Positioned(
                      top: -15,
                      child: Icon(Icons.workspace_premium_rounded, color: Colors.orange, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('💙fAM💚 ... ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('🇲🇦', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('1,688', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Help icon
          const Positioned(
            top: 20,
            right: 20,
            child: Icon(Icons.help_outline_rounded, color: Colors.purple, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFFFD54F),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Coins'),
          Tab(text: 'Honor Vouchers'),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Timer row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.purple, size: 18),
                const SizedBox(width: 4),
                const Text('18:42:24', style: TextStyle(color: Colors.black45, fontSize: 14)),
                const Spacer(),
                const Text('Today', style: TextStyle(color: Colors.black45, fontSize: 14)),
                const Icon(Icons.swap_vert_rounded, color: Colors.black45, size: 18),
              ],
            ),
          ),
          // List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              final rank = index + 2;
              return _buildRankItem(rank);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black26),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Kopcha ... ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('🇵🇰', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Row(
              children: [
                Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 14),
                SizedBox(width: 4),
                Text('700', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.close_rounded, size: 28, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
