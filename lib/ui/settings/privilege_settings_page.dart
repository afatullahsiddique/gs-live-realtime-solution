import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivilegeSettingsPage extends StatefulWidget {
  const PrivilegeSettingsPage({super.key});

  @override
  State<PrivilegeSettingsPage> createState() => _PrivilegeSettingsPageState();
}

class _PrivilegeSettingsPageState extends State<PrivilegeSettingsPage> {
  final Map<String, bool> _settings = {
    'Invisible Visitor': false,
    'Mystery Man In LIVE Room': false,
    'Mystery Man On Rank': false,
    'Invisible Online': false,
    'Exclusive Email Notification': false,
    'Hide Livestream Level': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privilege Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildToggleItem(
                  'Invisible Visitor',
                  "Visiting others without leaving a record, and others also can't see who visited the homepage.",
                ),
                _buildDivider(),
                _buildToggleItem(
                  'Mystery Man In LIVE Room',
                  "Appear as a 'Mystery Man' in the LIVE room — only the gift recipient can see your identity. (Float tags and speaker announcements will not apply when enabling this mode.)",
                ),
                _buildDivider(),
                _buildToggleItem(
                  'Mystery Man On Rank',
                  "Displayed on the rank as a 'Mystery Man'. After enabling the feature, your gifts won't appear on the host's fan ranking.",
                ),
                _buildDivider(),
                _buildToggleItem(
                  'Invisible Online',
                  "Always maintain an invisible status; enter live broadcast rooms invisibly.(The switch will automatically turn off when starting live streaming)",
                ),
                _buildDivider(),
                _buildToggleItem(
                  'Exclusive Email Notification',
                  "You will receive an exclusive email notification after the customer service team replies to your inquiry.",
                ),
                _buildDivider(),
                _buildToggleItem(
                  'Hide Livestream Level',
                  "Once turned on, others will not be able to see your livestream level when browsing your profile. (Android: 473; iOS: 397)",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.3),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _settings[title] ?? false,
            onChanged: (value) => setState(() => _settings[title] = value),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF5E5CFF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withValues(alpha: 0.05),
      indent: 16,
    );
  }
}
