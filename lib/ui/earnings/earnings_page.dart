import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 20, top: 10, bottom: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Official Talent Instruction',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.pink, blurRadius: 10, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                    // Invisible icon button to balance the row
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // What you need to become an official Talent
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'What you need to become an official Talent',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[400],
                                shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 5)],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildBulletPoint('Official Talent Requirements'),
                      const SizedBox(height: 10),
                      _buildBulletPoint(
                        'If you have earned at least 2,000,000 gems, then you can apply to be an official talent.',
                      ),
                      const SizedBox(height: 10),
                      _buildOrText(),
                      const SizedBox(height: 10),
                      _buildBulletPoint(
                        'If you have an Agency ID and agency you would like to join, you can apply with the Agency ID and Join into an Agency right away.',
                      ),
                      const SizedBox(height: 40),
                      // Why should you become an official talent?
                      _buildSectionTitle('Why should you become an official talent?'),
                      const SizedBox(height: 20),
                      _buildBulletPoint(
                        'You can earn real money from streaming. You will receive both an allowance and money from the gems you earn!',
                      ),
                      const SizedBox(height: 10),
                      _buildBulletPoint(
                        'When you broadcast, your stream will appear on the Popular category on the homepage. This way the most users will see you.',
                      ),
                      const SizedBox(height: 10),
                      _buildBulletPoint(
                        'Special placement in the Discovery section of the app and a New Star ribbon on your broadcast. We want everyone to know how special you are!',
                      ),
                      const SizedBox(height: 10),
                      _buildBulletPoint(
                        'Receive training, support and other perks from the team at GS LIVE and our crew of trusted agencies!',
                      ),
                      const SizedBox(height: 40),
                      // Notice
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Notice:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[400],
                                shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 5)],
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '\nGS LIVE does not allow streamer under 18 to stream. If you are under age, your application will not be accepted. Please apply after you turn 18 years old.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Gems Balance
                      _buildGemsInfo(),
                      const SizedBox(height: 20),
                      // Continue Button (Styled like Save button from screenshot)
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle continue logic
                            debugPrint('Continue button tapped!');
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Optional: "I have an Agency ID" link
                      const Center(
                        child: Text(
                          'I have an Agency ID',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.pink[400],
        shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 5)],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('●  ', style: TextStyle(color: Colors.white, fontSize: 14)),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildOrText() {
    return const Center(
      child: Text('Or', style: TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildGemsInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Gems Balance: 0 gems', style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 5),
        Text('Gems Required to Apply: 0 gems', style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
