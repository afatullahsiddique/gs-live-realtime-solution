import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/cubits/app_cubit.dart';
import '../../navigation/routes.dart';

// Import your AppCubit
// import '../../cubits/app_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildGroup([
              _buildItem(
                title: 'Account And Security',
                subtitle: 'Security Level: Low',
                subtitleColor: Colors.red,
                onTap: () => context.push(Routes.accountSecurity.path),
              ),
              _buildItem(title: 'Security Password', onTap: () => context.push(Routes.passwordSettings.path)),
              _buildItem(title: 'Language Setting', onTap: () => context.push(Routes.languageSetting.path)),
            ]),
            _buildGroup([
              _buildItem(title: 'Blacklist', onTap: () => context.push(Routes.blacklist.path)),
            ]),
            _buildGroup([
              _buildItem(title: 'Privilege Settings', onTap: () => context.push(Routes.privilegeSettings.path)),
              _buildItem(title: 'New Messages Notification', onTap: () => context.push(Routes.newMessagesNotification.path)),
              _buildItem(title: 'Privacy', onTap: () => context.push(Routes.privacy.path)),
            ]),
            _buildGroup([
              _buildItem(title: 'Version', trailingText: '5.4.526.0212', onTap: () {}),
              _buildItem(title: 'About GS', onTap: () => context.push(Routes.aboutPoppo.path)),
              _buildItem(title: 'Network Diagnostics', onTap: () {}),
              _buildItem(title: 'Clear Cache', onTap: () {}),
            ]),
            const SizedBox(height: 12),
            _buildFooterButton(
              text: 'Switch Account',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildFooterButton(
              text: 'Log Out',
              textColor: Colors.black, // The screenshot shows black text for Log Out, but usually it's red. Looking at image 0, it's black. Image 1 is also black. Wait, actually it's a separate card.
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 0, color: Color(0xFFF0F0F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem({
    required String title,
    String? subtitle,
    Color? subtitleColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black87),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: subtitleColor ?? Colors.grey),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 20),
        ],
      ),
    );
  }

  Widget _buildFooterButton({required String text, required VoidCallback onTap, Color? textColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textColor ?? Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final appCubit = GetIt.I<AppCubit>();
      await appCubit.logout();
      if (context.mounted) {
        context.go(Routes.login.path);
      }
    }
  }
}
