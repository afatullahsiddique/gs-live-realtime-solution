import 'package:flutter/material.dart';
import '../../../data/remote/firebase/video_room_services.dart';
import '../video_room_page.dart'; // Import to access the JoinRequest class

/// A bottom sheet that displays and manages join requests for a video room.
class VideoJoinRequestsBottomSheet extends StatefulWidget {
  final List<JoinRequest> initialJoinRequests;
  final String roomID;

  const VideoJoinRequestsBottomSheet({super.key, required this.initialJoinRequests, required this.roomID});

  @override
  State<VideoJoinRequestsBottomSheet> createState() => _VideoJoinRequestsBottomSheetState();
}

class _VideoJoinRequestsBottomSheetState extends State<VideoJoinRequestsBottomSheet> {
  late List<JoinRequest> _joinRequests;

  @override
  void initState() {
    super.initState();
    _joinRequests = List.from(widget.initialJoinRequests);
  }

  /// Builds a single row for a join request.
  Widget _buildRequestTile(BuildContext context, JoinRequest request) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: request.userPicture != null && request.userPicture!.isNotEmpty
            ? NetworkImage(request.userPicture!)
            : null,
        child: request.userPicture == null || request.userPicture!.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(request.userName, style: const TextStyle(color: Colors.white)),
      subtitle: const Text('Wants to join the call', style: TextStyle(color: Colors.white70)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              // Call the service to reject the request.
              VideoRoomService.rejectJoinRequest(widget.roomID, request.requestId);
              // Immediately remove from the local list for instant UI feedback.
              setState(() {
                _joinRequests.remove(request);
              });
              // If no requests are left, close the bottom sheet.
              if (_joinRequests.isEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Call the service to approve the request.
              VideoRoomService.approveJoinRequest(widget.roomID, request.requestId, request.userId);
              // Immediately remove from the local list.
              setState(() {
                _joinRequests.remove(request);
              });
              if (_joinRequests.isEmpty) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Join Requests (${_joinRequests.length})',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        Expanded(
          child: _joinRequests.isEmpty
              ? const Center(
                  child: Text('No pending requests', style: TextStyle(color: Colors.white70, fontSize: 16)),
                )
              : ListView.builder(
                  itemCount: _joinRequests.length,
                  itemBuilder: (context, index) {
                    final request = _joinRequests[index];
                    return _buildRequestTile(context, request);
                  },
                ),
        ),
      ],
    );
  }
}

/// A top-level function to display the video join requests bottom sheet.
/// This is what you will call from your VideoRoomPage.
void showVideoJoinRequestsBottomSheet({
  required BuildContext context,
  required List<JoinRequest> joinRequests,
  required String roomID,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: VideoJoinRequestsBottomSheet(initialJoinRequests: joinRequests, roomID: roomID),
      );
    },
  );
}
