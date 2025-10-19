import 'package:flutter/material.dart';
import '../video_room_page.dart';

/// A bottom sheet that displays a list of all participants in the video room.
class VideoParticipantsBottomSheet extends StatelessWidget {
  final List<VideoParticipant> participants;
  final String currentUserId;
  final String hostId; // To identify the host

  const VideoParticipantsBottomSheet({
    super.key,
    required this.participants,
    required this.currentUserId,
    required this.hostId,
  });

  @override
  Widget build(BuildContext context) {
    // Create a mutable copy to sort it.
    final sortedParticipants = List<VideoParticipant>.from(participants);

    // Sort the list to always show the host at the top.
    sortedParticipants.sort((a, b) {
      if (a.userId == hostId) return -1; // a is host, comes first
      if (b.userId == hostId) return 1;  // b is host, comes first
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
              return _buildParticipantTile(participant);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single row for a participant in the list.
  Widget _buildParticipantTile(VideoParticipant participant) {
    // Determine the role for the subtitle
    final String role = participant.userId == hostId ? 'Host' : 'Participant';
    final bool isCurrentUser = participant.userId == currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: participant.userPicture != null && participant.userPicture!.isNotEmpty
            ? NetworkImage(participant.userPicture!)
            : null,
        child: participant.userPicture == null || participant.userPicture!.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        participant.userName,
        style: TextStyle(
          color: isCurrentUser ? Colors.pink : Colors.white,
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(role, style: const TextStyle(color: Colors.white70)),
    );
  }
}

/// A top-level function to display the participants bottom sheet.
void showVideoParticipantsBottomSheet(BuildContext context, {
  required List<VideoParticipant> participants,
  required String currentUserId,
  required String hostId,
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
        ),
      );
    },
  );
}
