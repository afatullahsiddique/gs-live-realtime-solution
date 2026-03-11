import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';

class MallPage extends StatefulWidget {
  const MallPage({super.key});

  @override
  State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage> {
  String _selectedCategory = 'Popular';
  String _subFilter = 'Hot Picks';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Popular', 'icon': Icons.whatshot_rounded, 'color': Colors.redAccent},
    {'name': 'Honor', 'icon': Icons.military_tech_rounded, 'color': Colors.orangeAccent},
    {'name': 'Rare ID', 'icon': Icons.badge_rounded, 'color': Colors.redAccent[100]},
    {'name': 'Ride', 'icon': Icons.directions_car_rounded, 'color': Colors.purpleAccent},
    {'name': 'Profile Card', 'icon': Icons.contact_page_rounded, 'color': Colors.deepPurpleAccent},
    {'name': 'Avatar Frame', 'icon': Icons.account_circle_rounded, 'color': Colors.tealAccent[400]},
    {'name': 'Party Theme', 'icon': Icons.checkroom_rounded, 'color': Colors.tealAccent[400]},
    {'name': 'Chat Bubble', 'icon': Icons.chat_bubble_rounded, 'color': Colors.pinkAccent},
  ];

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
          'Store',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.orange, size: 28),
            onPressed: () => _showRankingDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildCategoryBar(),
              _buildSubFilterBar(),
              Expanded(
                child: _buildMainContent(),
              ),
              const SizedBox(height: 80), // Space for bottom bar
            ],
          ),
          _buildBottomBalanceBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name']),
            child: Container(
              width: 85,
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? cat['color'].withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cat['icon'],
                      color: isSelected ? cat['color'] : Colors.black26,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.black : Colors.black38,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubFilterBar() {
    if (_selectedCategory == 'Honor') return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSubFilterChip('Hot Picks'),
          const SizedBox(width: 12),
          _buildSubFilterChip('Latest'),
          const Spacer(),
          const Icon(Icons.list_rounded, color: Colors.black45),
        ],
      ),
    );
  }

  Widget _buildSubFilterChip(String label) {
    final isSelected = _subFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _subFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EAF6) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3F51B5) : Colors.black45,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedCategory == 'Honor') {
      return _buildHonorView();
    }
    
    // Grid view for other categories
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (_selectedCategory == 'Honor') {
              _showRankingDialog();
            } else {
              _showPurchaseSheet(index);
            }
          },
          child: _buildStoreItem(index),
        );
      },
    );
  }

  void _showRankingDialog() {
    showDialog(
      context: context,
      builder: (context) => const MallRankingDialog(),
    );
  }

  void _showPurchaseSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PurchaseDetailSheet(),
    );
  }

  Widget _buildStoreItem(int index) {
    final names = ['Aries', 'Flamewolf De...', 'Mars', 'Neptune', 'Cyberpunk', 'Fresh Orange', 'Sagittarius', 'Taurus', 'Libra'];
    final name = names[index % names.length];
    final price = (index + 1) * 1000 + (index % 3 == 0 ? 0 : 500);
    final isVoucher = index % 3 == 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                  ),
                  const Text('Hello~', style: TextStyle(fontSize: 10, color: Colors.black12)),
                  // Decoration placeholder
                  Icon(
                    _getCategoryIcon(),
                    size: 80,
                    color: Colors.orange.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isVoucher ? Icons.confirmation_number_rounded : Icons.monetization_on_rounded,
                      size: 14,
                      color: isVoucher ? Colors.orange[300] : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVoucher ? '${(index + 1) * 12}' : '$price',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (_selectedCategory) {
      case 'Avatar Frame': return Icons.account_circle_outlined;
      case 'Chat Bubble': return Icons.chat_bubble_outline;
      case 'Profile Card': return Icons.contact_page_outlined;
      default: return Icons.auto_awesome_rounded;
    }
  }

  Widget _buildHonorView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.brown),
                child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontSize: 12))),
              ),
              const SizedBox(width: 8),
              const Text('Honor Level: 0', style: TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.chevron_right_rounded, size: 18),
              const Spacer(),
              const Icon(Icons.description_outlined, size: 20, color: Colors.black45),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildHonorItem('Custom Ride - 2 Months', '10,000', 'Limit3/3', Icons.directions_car_rounded, isNew: true),
        _buildHonorItem('Supreme Box - Daily Sales', '200', 'Limit0/5', Icons.card_giftcard_rounded),
        _buildHonorItem('Moments Pin Card - 1h', '400', '', Icons.file_upload_outlined),
        _buildHonorItem('Honor Card - 2 Months', '1,200', '', Icons.badge_outlined),
        _buildHonorItem('Customized Gift-2 months', '3,000', '', Icons.redeem_rounded),
        _buildHonorItem('Account Unblocking', '400', '', Icons.verified_user_outlined),
      ],
    );
  }

  Widget _buildHonorItem(String title, String price, String limit, IconData icon, {bool isNew = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew) 
                  const Text('New', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(price, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          if (limit.isNotEmpty)
            Text(limit, style: const TextStyle(fontSize: 12, color: Colors.black38)),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildBottomBalanceBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            _buildBalanceChip(Icons.monetization_on_rounded, '0', Colors.orange),
            const SizedBox(width: 12),
            _buildBalanceChip(Icons.confirmation_number_rounded, '0', Colors.orange[300]!),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFFF5F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.backpack_outlined, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChip(IconData icon, String value, Color color) {
    return GestureDetector(
      onTap: () => context.push(Routes.topUp.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFF4F5BFF), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseDetailSheet extends StatelessWidget {
  const _PurchaseDetailSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(),
                  const SizedBox(height: 24),
                  const Text(
                    'Fresh Orange',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildOptionRow('Validity Period:', '15Days', isChip: true),
                  _buildOptionRow('Gift to Friends:', 'Select Friends >', isLink: true),
                  _buildOptionRow('Payment Method:', '', hasIcon: true),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          const Text(
            'Avatar Frame',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.05), Colors.blue.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD18E72), // Brownish profile placeholder
              ),
              child: const Center(
                child: Text('G', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ),
            ),
            // Frame decoration (Orange mockup)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withValues(alpha: 0.8), width: 8),
              ),
            ),
            // Oranges
            Positioned(
              bottom: 10,
              left: 20,
              child: Icon(Icons.circle, color: Colors.orange, size: 24),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: Icon(Icons.circle, color: Colors.orange, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String label, String value, {bool isChip = false, bool isLink = false, bool hasIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const Spacer(),
          if (isChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC5CAE9)),
              ),
              child: Text(value, style: const TextStyle(color: Color(0xFF3F51B5), fontSize: 12)),
            )
          else if (isLink)
            Text(value, style: const TextStyle(color: Colors.black38, fontSize: 14))
          else if (hasIcon)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC5CAE9)),
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.push(Routes.topUp.path),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F5BFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Go to Recharge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Short 🎫 30', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MallRankingDialog extends StatefulWidget {
  const MallRankingDialog({super.key});

  @override
  State<MallRankingDialog> createState() => _MallRankingDialogState();
}

class _MallRankingDialogState extends State<MallRankingDialog> with SingleTickerProviderStateMixin {
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Main Dialog Container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD1C4E9), width: 6), // Thick purple border
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 70), // Space for floating header
                _buildSubHeader(),
                _buildTabs(),
                _buildLeaderboard(),
              ],
            ),
          ),
          // Floating King Banner
          Positioned(
            top: -40,
            child: _buildKingHeader(),
          ),
          // Help Icon
          const Positioned(
            top: 20,
            right: 20,
            child: Icon(Icons.help_outline_rounded, color: Color(0xFF9575CD), size: 24),
          ),
          // Close Button at bottom
          Positioned(
            bottom: -70,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.black54, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKingHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Decorative Wings/Circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFCE93D8), Color(0xFFBA68C8)]),
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
            // Avatar
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF1A237E),
              child: Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 40),
            ),
            // Crown
            const Positioned(
              top: -10,
              child: Icon(Icons.workspace_premium_rounded, color: Colors.orangeAccent, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('KING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSubHeader() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💙fAM💚 ... ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('🇲🇦', style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text('1,688', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFFFD54F),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black26,
        tabs: const [
          Tab(text: 'Coins'),
          Tab(text: 'Honor Vouchers'),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: [
        // Timer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF9575CD), size: 16),
              const SizedBox(width: 4),
              const Text('18:42:24', style: TextStyle(color: Colors.black38, fontSize: 12)),
              const Spacer(),
              const Text('Today', style: TextStyle(color: Colors.black38, fontSize: 12)),
              const Icon(Icons.swap_vert_rounded, color: Colors.black38, size: 16),
            ],
          ),
        ),
        // List
        SizedBox(
          height: 350,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 6,
            itemBuilder: (context, index) {
              final rank = index + 2;
              return _buildRankItem(rank);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRankItem(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black26)),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE8EAF6),
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Kopcha ... 🇵🇰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Row(
            children: [
              const Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text('700', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
            ],
          ),
        ],
      ),
    );
  }
}
