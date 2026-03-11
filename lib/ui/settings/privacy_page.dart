import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _hideMicrophoneStatus = false;

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
          'Privacy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader('Live privacy'),
            _buildLivePrivacyItem(),
            _buildGroupHeader('Permission Privacy'),
            _buildPermissionPrivacyGroup(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLivePrivacyItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            const Text(
              'Hide the microphone status',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
        trailing: Switch(
          value: _hideMicrophoneStatus,
          onChanged: (value) => setState(() => _hideMicrophoneStatus = value),
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF5E5CFF),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.black.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _buildPermissionPrivacyGroup() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPermissionItem(
            'Allow GS to access your camera',
            'For taking pictures, recording videos, etc.',
            'Go settings',
          ),
          _buildDivider(),
          _buildPermissionItem(
            'Allow GS to access your voice messages',
            'For video recording and voice sending, etc.',
            'Go settings',
          ),
          _buildDivider(),
          _buildPermissionItem(
            'Allow the platform to get permission for your location',
            'Used to find nearby streamers',
            'On',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String subtitle, String trailingText) {
    return ListTile(
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.3),
            height: 1.4,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Colors.black.withValues(alpha: 0.2),
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
