import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewMessagesNotificationPage extends StatefulWidget {
  const NewMessagesNotificationPage({super.key});

  @override
  State<NewMessagesNotificationPage> createState() => _NewMessagesNotificationPageState();
}

class _NewMessagesNotificationPageState extends State<NewMessagesNotificationPage> {
  final Map<String, bool> _settings = {
    'Live room opening alerts': true,
    'Message notification switch': true,
    'Sound': true,
    'Vibrate': true,
    'Mutual followers': true,
    'My Following': true,
    'Stranger': true,
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
          'New Messages Notification',
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
            _buildGroupHeader('Message notifications'),
            _buildGroupedItems([
              'Live room opening alerts',
              'Message notification switch',
            ]),
            _buildGroupHeader('Message alert settings'),
            _buildGroupedItems([
              'Sound',
              'Vibrate',
            ]),
            _buildGroupHeader('Who can send me a private message?'),
            _buildGroupedItems([
              'Mutual followers',
              'My Following',
              'Stranger',
            ]),
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

  Widget _buildGroupedItems(List<String> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildToggleTile(item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withValues(alpha: 0.05),
                  indent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleTile(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      trailing: Switch(
        value: _settings[title] ?? false,
        onChanged: (value) => setState(() => _settings[title] = value),
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF5E5CFF),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.black.withValues(alpha: 0.05),
      ),
    );
  }
}
