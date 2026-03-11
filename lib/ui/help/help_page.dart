import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _selectedCategory = 'Frequent';

  final List<Map<String, String>> _categories = [
    {'name': 'Frequent', 'icon': '🔥'},
    {'name': 'Livestream', 'icon': '📹'},
    {'name': 'Recharge', 'icon': '💰'},
    {'name': 'Report', 'icon': '🛡️'},
    {'name': 'Account', 'icon': '👤'},
  ];

  final Map<String, List<Map<String, dynamic>>> _faqData = {
    'Frequent': [
      {
        'question': 'Why did my face authentication fail?',
        'answer': 'Face authentication might fail due to poor lighting, face obscuration, or moving too quickly. Please ensure you are in a well-lit area and follow the on-screen instructions closely.',
      },
      {
        'question': 'How to become an agent?',
        'answer': 'To become an agent, you typically need to apply through the official "Agent Center" or contact the support team with your credentials.',
      },
      {
        'question': 'Why can\'t the "Points to be confirmed" be withdrawn?',
        'answer': 'Points to be confirmed are usually under a holding period for verification. They will become available for withdrawal once the verification process is complete.',
      },
      {
        'question': 'I didn\'t receive salary after making withdrawal. What should I do?',
        'answer': '1) If your withdrawal order is under review or paying, please kindly be patient and wait. Your withdrawal request will be handled within 24 - 48 hours.\n2) If your withdrawal order showed successful but you did not receive the salary, please send message to "Help" then our related staff will check your issue further.',
      },
      {
        'question': 'How to become a coinseller?',
        'answer': 'Becoming a coinseller requires reaching out to the official platform administrators and meeting certain volume and reliability criteria.',
      },
      {
        'question': 'I didn\'t receive coins after topping up. What should I do?',
        'answer': 'Please verify your transaction in your payment app. If it was successful, wait up to 30 minutes. If coins still don\'t appear, contact support with your transaction ID.',
      },
      {
        'question': 'How to quit an agency?',
        'answer': 'Quitting an agency usually requires a mutual agreement or following the specific termination steps listed in your agency contract.',
      },
    ],
    'Livestream': [
      {
        'question': 'The live condition of male users',
        'answer': 'Male users must follow the same community guidelines as all users. Some regions may have specific registration requirements for streamers.',
      },
      {
        'question': 'How can I get a higher hourly reward for live streaming?',
        'answer': 'Higher rewards are often tied to streamer level, audience engagement, and consistent streaming hours. Check the "Streamer Center" for specific goals.',
      },
    ],
    'Recharge': [
      {'question': 'Available payment methods?', 'answer': 'We support various methods including Credit Cards, E-wallets, and Mobile banking.'},
    ],
    'Report': [
      {'question': 'How to report a user?', 'answer': 'You can report a user by clicking on their profile and selecting the report icon.'},
    ],
    'Account': [
      {'question': 'How to delete my account?', 'answer': 'Account deletion can be requested in the Settings menu under Account Security.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildCategoryGrid(),
                const SizedBox(height: 20),
                _buildFaqSection(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name']!),
            child: Container(
              width: (MediaQuery.of(context).size.width - 44) / 2,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8EAF6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFC5CAE9) : Colors.transparent,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cat['name']!,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF3F51B5) : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqSection() {
    final list = _faqData[_selectedCategory] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              _selectedCategory,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...list.map((item) => _buildExpansionTile(item)),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(Map<String, dynamic> item) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          item['question'],
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        iconColor: Colors.black45,
        collapsedIconColor: Colors.black45,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item['answer'],
              style: const TextStyle(fontSize: 13, color: Colors.black45, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push(Routes.myFeedback.path),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8EAF6),
                  foregroundColor: const Color(0xFF3F51B5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('My feedback', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F5BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Message feedback', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
