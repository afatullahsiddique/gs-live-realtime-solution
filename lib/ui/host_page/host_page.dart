import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/firebase/room_services.dart';
import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  bool isVideoParty = false;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // NEW: Dispose the controller to prevent memory leaks
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const Spacer(),
              _buildPartyTypeSelector(),
              const Spacer(),
              _buildStartLiveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => context.go(Routes.home.path),
          ),
          const Spacer(),
          Text(
            'Start Hosting',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildPartyTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: _buildPartyOption(
              icon: Icons.mic_rounded,
              label: 'Voice Party',
              isSelected: !isVideoParty,
              onTap: () => setState(() => isVideoParty = false),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildPartyOption(
              icon: Icons.videocam_rounded,
              label: 'Video Party',
              isSelected: isVideoParty,
              onTap: () => setState(() => isVideoParty = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.pink400, AppColors.pink600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.6) : Colors.pink.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartLiveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // MODIFIED: onTap now calls the new dialog method
          onTap: _showCreateRoomDialog,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [AppColors.pink400, AppColors.pink600],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 25, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 15)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Start Live',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    _passwordController.clear(); // Clear previous input

    // NEW: Get a reference to the router BEFORE the dialog is even shown.
    // This is the safest approach.
    final router = GoRouter.of(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a different name to avoid confusion
        return AlertDialog(
          backgroundColor: const Color(0xFF2d1b2b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Secure Your Room', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Password (optional)",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Start Live', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // Get the password before any async operations
                final password = _passwordController.text.trim();

                // Dismiss the dialog using its own context
                Navigator.of(dialogContext).pop();

                try {
                  String roomId = await RoomService.createRoom(password: password.isNotEmpty ? password : null);

                  // This check is still a crucial safety net!
                  if (!mounted) return;

                  if (!isVideoParty) {
                    // Use the 'router' variable we saved earlier, NOT the context.
                    router.pushReplacement(Routes.audioRoom.path, extra: {"roomId": roomId, "isHost": true});
                  } else {
                    // TODO: Implement navigation for Video Party
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error creating room: ${e.toString()}")));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
