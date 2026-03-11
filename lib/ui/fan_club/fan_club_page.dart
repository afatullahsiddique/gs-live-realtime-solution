import 'package:flutter/material.dart';

class FanClubPage extends StatefulWidget {
  const FanClubPage({super.key});

  @override
  State<FanClubPage> createState() => _FanClubPageState();
}

class _FanClubPageState extends State<FanClubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _subTabIndex = 0; // 0 for Joined club/groups, 1 for My club/group
  String _fanClubFilter = 'Lit'; // 'Lit' or 'Frozen'

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
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black38,
          labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          indicatorColor: Colors.black87,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Fan Club'),
            Tab(text: 'Fan group'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFanClubView(),
          _buildFanGroupView(),
        ],
      ),
    );
  }

  Widget _buildFanClubView() {
    return Column(
      children: [
        _buildSubTabBar(
          leftText: 'Joined club',
          rightText: 'My club',
          index: _subTabIndex,
          onTap: (i) => setState(() => _subTabIndex = i),
        ),
        if (_subTabIndex == 0) _buildFanClubFilters(),
        Expanded(child: _buildEmptyState()),
      ],
    );
  }

  Widget _buildFanGroupView() {
    return Column(
      children: [
        _buildSubTabBar(
          leftText: 'Joined groups',
          rightText: 'My group',
          index: _subTabIndex,
          onTap: (i) => setState(() => _subTabIndex = i),
        ),
        Expanded(child: _buildEmptyState()),
      ],
    );
  }

  Widget _buildSubTabBar({
    required String leftText,
    required String rightText,
    required int index,
    required Function(int) onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 32) / 2,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(0),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      leftText,
                      style: TextStyle(
                        color: index == 0 ? Colors.black87 : Colors.black45,
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(1),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      rightText,
                      style: TextStyle(
                        color: index == 1 ? Colors.black87 : Colors.black45,
                        fontWeight: index == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFanClubFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Lit'),
          const SizedBox(width: 12),
          _buildFilterChip('Frozen'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _fanClubFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _fanClubFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDDEE) : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF4081) : Colors.black54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recreating the hippo illustration with simple shapes
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // UFO Beam
                Container(
                  width: 120,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withValues(alpha: 0.05), Colors.blue.withValues(alpha: 0.2)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                // UFO
                Positioned(
                  top: 20,
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                // Hippo
                Positioned(
                  bottom: 30,
                  child: Icon(Icons.catching_pokemon, size: 80, color: const Color(0xFF7B88C6).withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No more data',
            style: TextStyle(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
