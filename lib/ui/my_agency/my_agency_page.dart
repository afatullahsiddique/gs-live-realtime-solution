import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyAgencyPage extends StatefulWidget {
  const MyAgencyPage({super.key});

  @override
  State<MyAgencyPage> createState() => _MyAgencyPageState();
}

class _MyAgencyPageState extends State<MyAgencyPage> {
  final TextEditingController _agentIdController = TextEditingController();

  @override
  void dispose() {
    _agentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Agency',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),
            _buildMethod1Card(),
            const SizedBox(height: 20),
            _buildMethod2Card(),
            const SizedBox(height: 24),
            _buildNoteSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C64F5), Color(0xFF5B4DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Gold coin floating
          Positioned(
            top: 30,
            right: 30,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB300),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 70,
            right: 80,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB300),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Choose',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Method 1 ',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'or ',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'Method 2',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          // Emoji/illustration in bottom right
          Positioned(
            bottom: 16,
            right: 24,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 36),
                ),
              ],
            ),
          ),
          // Heart floating
          const Positioned(
            top: 100,
            right: 110,
            child: Icon(Icons.favorite_rounded, color: Color(0xFFFF5252), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMethod1Card() {
    return _buildMethodCard(
      methodLabel: 'Method 1',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join agent',
            style: TextStyle(color: Color(0xFF3D3DBF), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agent ID will be provided by agent',
            style: TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _agentIdController,
            decoration: InputDecoration(
              hintText: "Please enter agent's ID",
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: null, // disabled by default until ID is entered
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B8FE0),
                disabledBackgroundColor: const Color(0xFFB0A0E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Please enter agent's ID",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethod2Card() {
    const userId = '73956308';
    const hostCode = '39pedu';

    return _buildMethodCard(
      methodLabel: 'Method 2',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Waiting for agent invitation',
            style: TextStyle(color: Color(0xFF3D3DBF), fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are required to provide the agent with your ID and host code',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildCopyRow('User ID: $userId', userId),
          const SizedBox(height: 12),
          _buildCopyRow('Host Code: No. $hostCode', hostCode, highlight: true),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String label, String valueToCopy, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0A0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: highlight
                ? Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Host Code: No. ',
                        style: const TextStyle(color: Color(0xFF444444), fontSize: 14),
                      ),
                      TextSpan(
                        text: valueToCopy,
                        style: const TextStyle(
                          color: Color(0xFF3D3DBF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  )
                : Text(label, style: const TextStyle(color: Color(0xFF444444), fontSize: 14)),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: valueToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.copy_rounded, color: Color(0xFFFF8C00), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({required String methodLabel, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7C6FCD), width: 2),
      ),
      child: Column(
        children: [
          // Wavy header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3DC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Center(
              child: Text(
                methodLabel,
                style: const TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fiber_manual_record, size: 6, color: Colors.black45),
              const SizedBox(width: 8),
              const Text(' Note ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(width: 8),
              const Icon(Icons.fiber_manual_record, size: 6, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoteItem('1. After joining the agency, host cannot leave agency without valid reason.'),
          const SizedBox(height: 8),
          _buildNoteItem('2. Host cannot join multiple agents!'),
          const SizedBox(height: 8),
          _buildNoteItem('3. Agent cannot join other agents!'),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.5),
    );
  }
}
