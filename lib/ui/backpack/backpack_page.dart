import 'package:flutter/material.dart';

class BackpackPage extends StatefulWidget {
  const BackpackPage({super.key});

  @override
  State<BackpackPage> createState() => _BackpackPageState();
}

class _BackpackPageState extends State<BackpackPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'My Outfit',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  indicatorColor: Colors.black,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Backpack Gifts'),
                    Tab(text: 'Avatar Frame'),
                    Tab(text: 'Party Theme'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.list_rounded, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackpackGiftsTab(),
          _buildAvatarFrameTab(),
          _buildEmptyTab('No Party Themes yet'),
        ],
      ),
    );
  }

  Widget _buildBackpackGiftsTab() {
    return _buildEmptyState('No backpack gift yet');
  }

  Widget _buildAvatarFrameTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'My Avatar Frame',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildEmptyState('No Avatar Frame yet'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Expired Avatar Frame',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildEmptyState('No Expired Avatar Frames yet'),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return _buildEmptyState(message);
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          Text(
            message,
            style: const TextStyle(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
