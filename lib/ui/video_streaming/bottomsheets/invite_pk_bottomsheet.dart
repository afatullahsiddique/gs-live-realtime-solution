import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/auto_scroll_text.dart';
import '../../../data/remote/firebase/video_room_services.dart';
import '../../../data/remote/firebase/profile_services.dart';
import '../../../theme/app_theme.dart';

void showInvitePKBottomSheet(
  BuildContext context, {
  required List<PKInvite> pendingInvites,
  required String currentRoomId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return InvitePKBottomSheet(
            scrollController: scrollController,
            pendingInvites: pendingInvites,
            currentRoomId: currentRoomId,
          );
        },
      );
    },
  );
}

class InvitePKBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<PKInvite> pendingInvites;
  final String currentRoomId;

  const InvitePKBottomSheet({
    super.key,
    required this.scrollController,
    required this.pendingInvites,
    required this.currentRoomId,
  });

  @override
  State<InvitePKBottomSheet> createState() => _InvitePKBottomSheetState();
}

class _InvitePKBottomSheetState extends State<InvitePKBottomSheet> {
  late Future<List<SimpleUser>> _mutualsFuture;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _mutualsFuture = ProfileService.getMutualsList(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Invite PK',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          if (widget.pendingInvites.isNotEmpty) _buildReceivedInvitesSection(widget.pendingInvites),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              children: [
                Text(
                  'Available to Invite',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SimpleUser>>(
              future: _mutualsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pink));
                }
                if (snapshot.hasError) {
                  return _EmptyListWidget(icon: Icons.error_outline, message: 'Failed to load list: ${snapshot.error}');
                }

                final allMutuals = snapshot.data ?? [];

                final availableHosts = allMutuals.where((user) => user.currentRoomId != null).toList();

                if (availableHosts.isEmpty) {
                  return const _EmptyListWidget(
                    icon: Icons.people_outline,
                    message: 'No mutuals are currently hosting.',
                  );
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: availableHosts.length,
                  itemBuilder: (context, index) {
                    final user = availableHosts[index];
                    return _buildUserRow(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedInvitesSection(List<PKInvite> invites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Received Invites',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];
            return _buildReceivedInviteRow(invite);
          },
        ),
        const Divider(color: Colors.white24, height: 1, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildReceivedInviteRow(PKInvite invite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (invite.senderHostPicture != null && invite.senderHostPicture!.isNotEmpty)
                ? NetworkImage(invite.senderHostPicture!)
                : null,
            child: (invite.senderHostPicture == null || invite.senderHostPicture!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AutoScrollText(
              text: invite.senderHostName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              VideoRoomService.rejectPKInvite(widget.currentRoomId, invite);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              // --- MODIFIED: Pass invite to acceptPKInvite ---
              VideoRoomService.acceptPKInvite(widget.currentRoomId, invite);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PK accepted with ${invite.senderHostName}!'), backgroundColor: Colors.green),
              );
              // The room listener will handle starting the video
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(SimpleUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (user.pictureUrl != null && user.pictureUrl!.isNotEmpty)
                ? NetworkImage(user.pictureUrl!)
                : null,
            child: (user.pictureUrl == null || user.pictureUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AutoScrollText(
              text: user.name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            // --- MODIFIED: Show timer selection dialog first ---
            onPressed: () => _showTimerSelectionDialog(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Invite', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- NEW: Timer Selection Dialog ---
  Future<void> _showTimerSelectionDialog(SimpleUser user) async {
    final int? selectedDuration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Set PK Duration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('5 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(5),
            ),
            ListTile(
              title: const Text('7 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(7),
            ),
            ListTile(
              title: const Text('10 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(10),
            ),
          ],
        ),
      ),
    );

    if (selectedDuration != null && mounted) {
      _sendInvite(user, selectedDuration);
    }
  }

  // --- NEW: Send Invite Logic (extracted) ---
  Future<void> _sendInvite(SimpleUser user, int durationInMinutes) async {
    try {
      await VideoRoomService.sendPKInvite(
        senderRoomId: widget.currentRoomId,
        receiverUser: user,
        durationInMinutes: durationInMinutes,
      );
      if (mounted) {
        Navigator.pop(context); // Close the main bottom sheet
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PK invite sent!'), backgroundColor: Colors.pink));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send invite: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
}

class _EmptyListWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyListWidget({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- PKInvite Model (MODIFIED) ---
class PKInvite {
  final String id; // The document ID (which is the sender's room ID)
  final String senderRoomId;
  final String senderHostId;
  final String senderHostName;
  final String? senderHostPicture;

  final String receiverRoomId;
  final String receiverHostId;

  final String status; // 'pending', 'accepted'
  final Timestamp createdAt;
  final int durationInMinutes; // --- NEW ---

  PKInvite({
    required this.id,
    required this.senderRoomId,
    required this.senderHostId,
    required this.senderHostName,
    this.senderHostPicture,
    required this.receiverRoomId,
    required this.receiverHostId,
    required this.status,
    required this.createdAt,
    required this.durationInMinutes, // --- NEW ---
  });

  factory PKInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PKInvite(
      id: doc.id,
      senderRoomId: data['senderRoomId'] ?? '',
      senderHostId: data['senderHostId'] ?? '',
      senderHostName: data['senderHostName'] ?? 'Unknown Host',
      senderHostPicture: data['senderHostPicture'],
      receiverRoomId: data['receiverRoomId'] ?? '',
      receiverHostId: data['receiverHostId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      durationInMinutes: data['durationInMinutes'] ?? 5, // --- NEW (default to 5) ---
    );
  }
}
