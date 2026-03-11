// lib/ui/host_page/live_application_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';

class LiveApplicationPage extends StatelessWidget {
  const LiveApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context),
            const SizedBox(height: 24),
            _buildConditionsSection(),
            const Spacer(),
            _buildLiveNowButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Live application',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Balance the back button
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live application conditions',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildConditionRow(
            title: 'Face Authentication',
            subtitle: 'Please complete authentication process first.',
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          _buildConditionRow(
            title: 'Live photo',
            subtitle: 'Please upload the live cover again',
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          _buildConditionRow(
            title: 'Wealth level ≥ level 5',
            subtitle: 'Only Wealth level reaches 5 can start to live',
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7B68EE),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Color(0xFF7B68EE),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNowButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.push(Routes.hostPage.path);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB0A8E0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Live now',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
