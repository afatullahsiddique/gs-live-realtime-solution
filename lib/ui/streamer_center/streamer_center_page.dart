import 'package:flutter/material.dart';

class StreamerCenterPage extends StatefulWidget {
  const StreamerCenterPage({super.key});

  @override
  State<StreamerCenterPage> createState() => _StreamerCenterPageState();
}

class _StreamerCenterPageState extends State<StreamerCenterPage> {
  int _selectedTimeFilter = 0; // 0: Today, 1: This week, 2: This month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildLiveStreamDataCard(),
                _buildLastStreamReportCard(),
                _buildInteractivityToolsCard(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFFBFBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Streamer Center',
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance for back button
              ],
            ),
            const Text(
              'ID:73956308',
              style: TextStyle(color: Color(0xFF999999), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamDataCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Stream Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              Row(
                children: [
                  Text('More data', style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.4))),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black.withValues(alpha: 0.2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeFilterPill('Today', 0),
              const SizedBox(width: 8),
              _buildTimeFilterPill('This week', 1),
              const SizedBox(width: 8),
              _buildTimeFilterPill('This month', 2),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            children: [
              _buildDataMetric('00:00:00', 'Hours of Live Streaming', showHelp: true),
              _buildDataMetric('0', 'Won points'),
              _buildDataMetric('0', 'New followers'),
              _buildDataMetric('0', 'Average viewers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterPill(String label, int index) {
    bool isSelected = _selectedTimeFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EAF6) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF7E57C2) : const Color(0xFF999999),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDataMetric(String value, String label, {bool showHelp = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            if (showHelp) ...[
              const SizedBox(width: 4),
              Icon(Icons.help_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.2)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLastStreamReportCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Stream Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 4),
          const Text(
            'No data available (Only data from the past 90 days is shown)',
            style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 16),
          _buildCoverUploadSection(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            children: [
              _buildDataMetric('00:00:00', 'Hours of Live Streaming'),
              _buildDataMetric('0', 'Won points'),
              _buildDataMetric('0', 'New followers'),
              _buildDataMetric('0', 'Audiences'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildDashedPlaceholder(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload your own cover and start high-quality live streaming',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Upload a new cover',
                    style: TextStyle(color: Color(0xFF7E57C2), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1, style: BorderStyle.solid), // Should ideally be dashed
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: const Center(
        child: Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFD0D0D0), size: 32),
      ),
    );
  }

  Widget _buildInteractivityToolsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactivity Tools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 20),
          _buildToolItem(
              'Fireworks', 'Ignite the Fireworks to hype up the room', Icons.wb_sunny_rounded, Colors.orangeAccent),
          _buildToolItem(
              'Lucky Box', 'Distribute a Lucky Box to get more followers fast', Icons.card_giftcard_rounded, Colors.redAccent),
          _buildToolItem(
              'PK', 'Start PK to increase engagement and revenue', Icons.flash_on_rounded, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildToolItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 100,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF536DFE), Color(0xFF3D5AFE)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D5AFE).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Start Streaming',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
