// lib/ui/host/host_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/firebase/live_streaming_services.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../data/remote/firebase/video_room_services.dart';
import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

// Enum to manage the selected party type
enum PartyType { voice, video, stream }

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  // Use the enum for state
  PartyType _selectedPartyType = PartyType.voice;
  bool _isLoading = false;

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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => context.go(Routes.home.path),
          ),
          const Spacer(),
          const Text(
            'Start Hosting',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  // --- MODIFIED: Party Type Selector ---
  Widget _buildPartyTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), // Reduced horizontal margin to fit 3
      child: Row(
        children: [
          Expanded(
            child: _buildPartyOption(
              icon: Icons.mic_rounded,
              label: 'Voice Party',
              isSelected: _selectedPartyType == PartyType.voice,
              onTap: () => setState(() => _selectedPartyType = PartyType.voice),
            ),
          ),
          // const SizedBox(width: 12),
          // Expanded(
          //   child: _buildPartyOption(
          //     icon: Icons.videocam_rounded,
          //     label: 'Video Party',
          //     isSelected: _selectedPartyType == PartyType.video,
          //     onTap: () => setState(() => _selectedPartyType = PartyType.video),
          //   ),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPartyOption(
              icon: Icons.cell_tower, // New icon for streaming
              label: 'Live Stream',
              isSelected: _selectedPartyType == PartyType.stream,
              onTap: () => setState(() => _selectedPartyType = PartyType.stream),
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        // Adjusted padding
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
            Icon(icon, size: 40, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6)), // Smaller icon
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 14, // Smaller text
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
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
          // 1. Disable button when loading
          onTap: _isLoading ? null : _startLive,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              // 3. Change gradient when loading
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade800],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [AppColors.pink400, AppColors.pink600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 25, offset: const Offset(0, 10)),
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 15)),
                    ],
            ),
            // 2. Show loading indicator
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Start Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // --- MODIFIED: _startLive Method ---
  Future<void> _startLive() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      switch (_selectedPartyType) {
        case PartyType.voice:
          String roomId = await RoomService.createRoom();
          if (!mounted) return;
          context.pushReplacement(Routes.audioRoom.path, extra: {"roomId": roomId, "isHost": true});
          break;
        case PartyType.video:
          String roomId = await VideoRoomService.createRoom();
          if (!mounted) return;
          context.pushReplacement(Routes.videoRoom.path, extra: {"roomId": roomId, "isHost": true});
          break;
        case PartyType.stream:
          String roomId = await LiveStreamService.createRoom();
          if (!mounted) return;
          // **NOTE**: You must define this route in your GoRouter configuration.
          // Example: '/live-stream'
          // I'll assume you have a route constant for it like `Routes.liveStream.path`
          context.pushReplacement(Routes.liveStream.path, extra: {"roomId": roomId, "isHost": true});
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating room: ${e.toString()}")));
      setState(() {
        _isLoading = false;
      });
    }
  }
}
