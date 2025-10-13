import 'package:flutter/material.dart';
import '../audio_room_page.dart';
import '../audio_room_page_v2.dart'; // Import to access the RoomParticipant class

/// A bottom sheet that displays a list of all participants in the room.
class ParticipantsBottomSheet extends StatelessWidget {
  final List<RoomParticipant> participants;
  final String currentUserId;

  const ParticipantsBottomSheet({
    super.key,
    required this.participants,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Create a mutable copy of the list to sort it.
    final sortedParticipants = List<RoomParticipant>.from(participants);

    // Sort the list based on role priority: Host > Co-host > Speaker > Listener
    sortedParticipants.sort((a, b) {
      int getRoleValue(RoomParticipant p) {
        if (p.seatNo == 0) return 0; // Host
        if (p.isCoHost) return 1;   // Co-host
        if (p.seatNo > 0) return 2;   // Speaker
        return 3;                   // Listener
      }
      return getRoleValue(a).compareTo(getRoleValue(b));
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
  Widget _buildParticipantTile(RoomParticipant participant) {
    // Determine the role for the subtitle
    String role = 'Listener';
    if (participant.seatNo == 0) {
      role = 'Host';
    } else if (participant.isCoHost) {
      role = 'Co-host';
    } else if (participant.seatNo > 0) {
      role = 'Speaker';
    }

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
void showParticipantsBottomSheet(BuildContext context, {
  required List<RoomParticipant> participants,
  required String currentUserId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true, // Allows the sheet to take up more screen space
    builder: (context) {
      // Use 70% of the screen height to avoid covering the whole screen
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: ParticipantsBottomSheet(
          participants: participants,
          currentUserId: currentUserId,
        ),
      );
    },
  );
}