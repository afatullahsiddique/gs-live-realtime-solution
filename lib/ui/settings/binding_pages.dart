import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';

// --- Shared Components ---

class BindingHeader extends StatelessWidget {
  final String title;
  const BindingHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Wave/Character Header
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4B49FD), Color(0xFF6362FF)],
            ),
          ),
          child: Stack(
            children: [
              // Character Illustration (Simplified Mockup)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Female character placeholder
                      Container(
                        width: 80,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD54F),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 10),
                      // Male character placeholder
                      Container(
                        width: 80,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        ),
                        child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
              ),
              // GS LIVE Text
              Positioned(
                bottom: 40,
                right: 20,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Text(
                    'GS LIVE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
        // Overlapping White Body with Curves
        Padding(
          padding: const EdgeInsets.only(top: 220),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Binding Selection Page ---

class BindingSelectionPage extends StatefulWidget {
  const BindingSelectionPage({super.key});

  @override
  State<BindingSelectionPage> createState() => _BindingSelectionPageState();
}

class _BindingSelectionPageState extends State<BindingSelectionPage> {
  int _selectedIndex = 0; // 0 for Email, 1 for Phone

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BindingHeader(title: 'Please bind your phone number or email first'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Email Option
                  _buildOption(
                    index: 0,
                    label: 'Email',
                    isRecommended: true,
                  ),
                  const SizedBox(height: 16),
                  // Phone Option
                  _buildOption(
                    index: 1,
                    label: 'Phone number',
                    isRecommended: false,
                  ),
                  const SizedBox(height: 80),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedIndex == 0) {
                          context.push(Routes.bindEmail.path);
                        } else {
                          context.push(Routes.bindPhone.path);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E5CFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        elevation: 0,
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Terms info
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black45, fontSize: 13),
                      children: [
                        const TextSpan(text: 'I have read and agreed the\n'),
                        TextSpan(
                          text: 'GS Live Terms Of Service',
                          style: const TextStyle(color: Color(0xFF5E5CFF)),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(color: Color(0xFF5E5CFF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required int index, required String label, bool isRecommended = false}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF3F2FF) : const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF5E5CFF) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? const Color(0xFF5E5CFF) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF5E5CFF) : Colors.black12,
                      width: 1.5,
                    ),
                    color: isSelected ? const Color(0xFF5E5CFF) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5CFF),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF5E5CFF).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Text(
                  'Recommend',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Bind Phone Page ---

class BindPhonePage extends StatefulWidget {
  const BindPhonePage({super.key});

  @override
  State<BindPhonePage> createState() => _BindPhonePageState();
}

class _BindPhonePageState extends State<BindPhonePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BindingHeader(title: 'Bind a phone'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Input Field
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: const Color(0xFF5E5CFF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        // Fake Country Selector
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 16,
                              color: Colors.green[800], // Fake flag
                              child: const Icon(Icons.circle, color: Colors.red, size: 8),
                            ),
                            const SizedBox(width: 8),
                            const Text('+880', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: VerticalDivider(width: 20, thickness: 1, color: Colors.black12),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            onChanged: (val) => setState(() => _isValid = val.length > 5),
                            decoration: const InputDecoration(
                              hintText: 'Please enter your phone number.',
                              hintStyle: TextStyle(fontSize: 14, color: Colors.black26),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E5CFF),
                        disabledBackgroundColor: const Color(0xFF5E5CFF).withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        elevation: 0,
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Bind Email Page ---

class BindEmailPage extends StatefulWidget {
  const BindEmailPage({super.key});

  @override
  State<BindEmailPage> createState() => _BindEmailPageState();
}

class _BindEmailPageState extends State<BindEmailPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BindingHeader(title: 'Bind mailbox'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Input Field
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: const Color(0xFF5E5CFF).withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => setState(() => _isValid = val.contains('@')),
                      decoration: const InputDecoration(
                        hintText: 'Please fill in your email address',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.black26),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E5CFF),
                        disabledBackgroundColor: const Color(0xFF5E5CFF).withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        elevation: 0,
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Terms info
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black45, fontSize: 13),
                      children: [
                        const TextSpan(text: 'I have read and agreed the\n'),
                        TextSpan(
                          text: 'GS Live Terms Of Service',
                          style: const TextStyle(color: Color(0xFF5E5CFF)),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(color: Color(0xFF5E5CFF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
