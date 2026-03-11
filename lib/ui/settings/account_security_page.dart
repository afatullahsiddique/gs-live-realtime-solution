import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

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
          'Account And Security',
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
          children: [
            const SizedBox(height: 40),
            // Security Level Shield
            _buildSecurityHeader(),
            const SizedBox(height: 30),
            // Section Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Binding a mobile number or email can raise the security level to Medium.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Primary Security Options
            _buildGroupedItems([
              _SecurityItem(
                icon: Icons.lock_outline_rounded,
                title: 'Set password',
                onTap: () {},
              ),
              _SecurityItem(
                icon: Icons.smartphone_rounded,
                title: 'Phone number',
                trailing: 'Bind',
                onTap: () => context.push(Routes.bindSelection.path),
              ),
              _SecurityItem(
                icon: Icons.email_outlined,
                title: 'Email',
                trailing: 'Bind',
                hasNotification: true,
                onTap: () => context.push(Routes.bindSelection.path),
              ),
            ]),
            const SizedBox(height: 12),
            // Third-party Bindings
            _buildGroupedItems([
              _SecurityItem(
                icon: Icons.g_mobiledata_rounded,
                title: 'Google',
                trailing: 'Garbage Value',
                trailingColor: Colors.black.withValues(alpha: 0.4),
                onTap: () {},
              ),
              _SecurityItem(
                icon: Icons.facebook_outlined,
                title: 'Facebook',
                trailing: 'Bind',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 12),
            // Device Management
            _buildGroupedItems([
              _SecurityItem(
                icon: Icons.devices_other_rounded,
                title: 'Device management',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 12),
            // Cancel Account
            _buildGroupedItems([
              _SecurityItem(
                title: 'Cancel account',
                centerTitle: true,
                hideArrow: true,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Red Shield with Clipper
            ClipPath(
              clipper: ShieldClipper(),
              child: Container(
                width: 70,
                height: 85,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF7B7B), Color(0xFFFF5252)],
                  ),
                ),
              ),
            ),
            const Icon(Icons.priority_high_rounded, color: Colors.white, size: 36),
          ],
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Your account security level is low, please complete the relevant information',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedItems(List<_SecurityItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              _buildSimpleTile(item),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleTile(_SecurityItem item) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: item.icon != null
          ? Icon(item.icon, color: Colors.black, size: 22)
          : null,
      title: item.centerTitle
          ? Center(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            )
          : Text(
              item.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.hasNotification)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          if (item.trailing != null)
            Text(
              item.trailing!,
              style: TextStyle(
                color: item.trailingColor ?? Colors.black.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          const SizedBox(width: 4),
          if (!item.hideArrow)
            Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.2), size: 20),
        ],
      ),
    );
  }
}

class _SecurityItem {
  final IconData? icon;
  final String title;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback onTap;
  final bool hasNotification;
  final bool centerTitle;
  final bool hideArrow;

  _SecurityItem({
    this.icon,
    required this.title,
    this.trailing,
    this.trailingColor,
    required this.onTap,
    this.hasNotification = false,
    this.centerTitle = false,
    this.hideArrow = false,
  });
}

class ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.7);
    path.quadraticBezierTo(size.width, size.height, size.width * 0.5, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.7);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
