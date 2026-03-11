import 'package:flutter/material.dart';

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> with SingleTickerProviderStateMixin {
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
      backgroundColor: const Color(0xFF1B2412), // Dark olive/green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Wealth Level'),
            Tab(text: 'Livestream Level'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => _showLevelDetails(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B2412),
              const Color(0xFF0F140A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildWealthLevelView(),
            _buildLivestreamLevelView(),
          ],
        ),
      ),
    );
  }

  Widget _buildWealthLevelView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelCard(
            level: 1,
            progress: 0.1,
            distance: '3,000',
            icon: Icons.diamond_rounded,
            iconColor: Colors.greenAccent[100]!,
          ),
          const SizedBox(height: 24),
          const Text(
            'My Benefits',
            style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            'Special Entry Effect',
            'Check for details >',
            Icons.keyboard_double_arrow_up_rounded,
            Colors.green[400]!,
            hasLevelBadge: true,
          ),
          const SizedBox(height: 32),
          const Text(
            'Locked Benefits',
            style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildLockedSection('Lv.5', [
            _buildBenefitItem('Wealth Lv.5', 'Wealth level reaches Lv.5', Icons.hexagon_rounded, Colors.amber, isLocked: true),
            _buildBenefitItem('Special Entry Effect', 'Visible to live rooms with < 200 people', Icons.keyboard_double_arrow_up_rounded, Colors.green[400]!, isLocked: true),
          ]),
          _buildLockedSection('Lv.10', [
            _buildBenefitItem('Wealth Lv.10', 'Wealth level reaches Lv.10', Icons.hexagon_rounded, Colors.blueAccent, isLocked: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildLivestreamLevelView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelCard(
            level: 1,
            progress: 0.05,
            distance: '10,000',
            icon: Icons.eco_rounded,
            iconColor: Colors.lightGreenAccent[400]!,
          ),
          const SizedBox(height: 24),
          const Text(
            'Locked Benefits',
            style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildLockedSection('Lv.3', [
            _buildBenefitItem('Level-Up Effect', 'Visible in current live room', Icons.stars_rounded, Colors.pinkAccent, isLocked: true),
          ]),
          _buildLockedSection('Lv.5', [
            _buildBenefitItem('Livestream Lv.5', 'Livestream level reaches Lv.5', Icons.eco_rounded, Colors.greenAccent, isLocked: true),
          ]),
          _buildLockedSection('Lv.10', [
            _buildBenefitItem('Livestream Lv.10', 'Livestream level reaches Lv.10', Icons.spa_rounded, Colors.lightBlueAccent, isLocked: true),
            _buildBenefitItem('Level-Up Effect', 'Visible in current live room', Icons.stars_rounded, Colors.deepOrangeAccent, isLocked: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required int level,
    required double progress,
    required String distance,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$level',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: -12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'The distance to upgrade :$distance',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isLocked = false,
    bool hasLevelBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasLevelBadge)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_drop_up, color: Colors.white, size: 16),
                        Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isLocked ? Colors.white24 : Colors.amber.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: color, size: 40),
        ],
      ),
    );
  }

  Widget _buildLockedSection(String level, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 4),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(
                level,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...items,
      ],
    );
  }

  void _showLevelDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LevelDetailsSheet(),
    );
  }
}

class _LevelDetailsSheet extends StatefulWidget {
  const _LevelDetailsSheet();

  @override
  State<_LevelDetailsSheet> createState() => _LevelDetailsSheetState();
}

class _LevelDetailsSheetState extends State<_LevelDetailsSheet> with SingleTickerProviderStateMixin {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B3A), // Dark purple/blue
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Tab bar and Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 40), // Spacer for center alignment
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Wealth Level'),
                      Tab(text: 'Livestream Level'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Level',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Points required to upgrade',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLevelTable('wealth'),
                _buildLevelTable('livestream'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTable(String type) {
    // Simulated data based on image
    final List<Map<String, dynamic>> data = List.generate(20, (index) {
      final level = index + 1;
      String points = '0';
      if (level == 2) {
        points = type == 'wealth' ? '3,000' : '10,000';
      }
      if (level == 3) {
        points = type == 'wealth' ? '15,000' : '70,000';
      }
      if (level == 4) {
        points = type == 'wealth' ? '50,000' : '250,000';
      }
      if (level > 4) {
        points = '${level * 1000 * (level - 2)}00'; // Simulation
      }

      return {'level': level, 'points': points};
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final level = item['level'] as int;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: _buildLevelBadge(level, type),
                ),
              ),
               Expanded(
                flex: 2,
                child: Text(
                  item['points'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(int level, String type) {
    Color bgColor = Colors.lightGreen;
    IconData icon = Icons.eco_rounded; // Default for livestream

    if (type == 'wealth') {
      icon = Icons.diamond_rounded;
      if (level < 5) {
        bgColor = const Color(0xFF90EE90);
      } else if (level < 10) {
        bgColor = const Color(0xFF4DD0E1);
      } else {
        bgColor = const Color(0xFF64B5F6);
      }
    } else {
      if (level < 5) {
        bgColor = const Color(0xFFCDDC39);
      } else if (level < 10) {
        bgColor = const Color(0xFF4CAF50);
      } else if (level < 15) {
        bgColor = const Color(0xFF00BCD4);
      } else {
        bgColor = const Color(0xFF2196F3);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$level',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
