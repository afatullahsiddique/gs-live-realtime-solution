import 'package:flutter/material.dart';
import 'package:cute_live/ui/video_streaming/bottomsheets/profile_info_bottomsheet.dart';
import '../../../core/widgets/auto_scroll_text.dart';
import '../../../data/remote/firebase/profile_services.dart';
import '../video_room_page.dart';

/// A bottom sheet that displays a list of all participants in the video room.
class VideoParticipantsBottomSheet extends StatelessWidget {
  final List<VideoParticipant> participants;
  final String currentUserId;
  final String hostId; // To identify the host
  final String roomId;

  const VideoParticipantsBottomSheet({
    super.key,
    required this.participants,
    required this.currentUserId,
    required this.hostId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    // Create a mutable copy to sort it.
    final sortedParticipants = List<VideoParticipant>.from(participants);

    // Sort the list to always show the host at the top.
    sortedParticipants.sort((a, b) {
      if (a.userId == hostId) return -1; // a is host, comes first
      if (b.userId == hostId) return 1; // b is host, comes first
      return a.userName.compareTo(b.userName); // Alphabetical for others
    });

    return Column(
      children: [
        // --- Header ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Participants (${participants.length})',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        // --- Participants List ---
        Expanded(
          child: ListView.builder(
            itemCount: sortedParticipants.length,
            itemBuilder: (context, index) {
              final participant = sortedParticipants[index];
              return _buildParticipantTile(context, participant);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single row for a participant in the list.
  Widget _buildParticipantTile(BuildContext context, VideoParticipant participant) {
    final String role = participant.userId == hostId ? 'Host' : 'Participant';
    final bool isCurrentUser = participant.userId == currentUserId;

    return ListTile(
      onTap: () {
        // Close this bottom sheet first
        Navigator.of(context).pop();
        // Show the new profile bottom sheet
        showProfileInfoBottomSheet(context, userId: participant.userId, hostId: hostId, roomId: roomId);
      },
      leading: CircleAvatar(
        backgroundImage: participant.userPicture != null && participant.userPicture!.isNotEmpty
            ? NetworkImage(participant.userPicture!)
            : null,
        child: participant.userPicture == null || participant.userPicture!.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: AutoScrollText(
        text: participant.userName,
        style: TextStyle(
          color: isCurrentUser ? Colors.pink : Colors.white,
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(role, style: const TextStyle(color: Colors.white70)),
      // --- Follow/Unfollow Button ---
      trailing: isCurrentUser
          ? null
          : StreamBuilder<bool>(
              stream: ProfileService.isFollowing(participant.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    width: 80,
                    child: Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }

                final bool isFollowing = snapshot.data ?? false;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey.shade800 : Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () async {
                    try {
                      if (isFollowing) {
                        await ProfileService.unfollowUser(participant.userId);
                      } else {
                        await ProfileService.followUser(participant.userId);
                      }
                    } catch (e) {
                      debugPrint('Error following/unfollowing user: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                );
              },
            ),
    );
  }
}

/// A top-level function to display the participants bottom sheet.
void showVideoParticipantsBottomSheet(
  BuildContext context, {
  required List<VideoParticipant> participants,
  required String currentUserId,
  required String hostId,
  required String roomId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: VideoParticipantsBottomSheet(
          participants: participants,
          currentUserId: currentUserId,
          hostId: hostId,
          roomId: roomId,
        ),
      );
    },
  );
}
