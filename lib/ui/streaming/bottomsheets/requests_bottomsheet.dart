import 'package:flutter/material.dart';

import '../../../data/remote/firebase/room_services.dart';
class RequestsBottomSheet extends StatefulWidget {
  final List<dynamic> initialCoHostRequests;
  final List<dynamic> initialSpeakerRequests;
  final String roomID;

  const RequestsBottomSheet({
    Key? key,
    required this.initialCoHostRequests,
    required this.initialSpeakerRequests,
    required this.roomID,
  }) : super(key: key);

  @override
  State<RequestsBottomSheet> createState() => _RequestsBottomSheetState();
}

class _RequestsBottomSheetState extends State<RequestsBottomSheet> {
  // Local copies of the request lists to manage state internally.
  late List<dynamic> _coHostRequests;
  late List<dynamic> _speakerRequests;

  @override
  void initState() {
    super.initState();
    // Create mutable copies of the initial lists passed to the widget.
    _coHostRequests = List.from(widget.initialCoHostRequests);
    _speakerRequests = List.from(widget.initialSpeakerRequests);
  }

  // Helper to build a single request list tile.
  Widget _buildRequestTile({
    required dynamic request,
    required String subtitle,
    required Future<void> Function() onApprove,
    required VoidCallback onStateChange, // To update the local list
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: request.userPicture != null ? NetworkImage(request.userPicture!) : null,
        child: request.userPicture == null ? const Icon(Icons.person) : null,
      ),
      title: Text(request.userName, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            child: const Text('Reject', style: TextStyle(color: Colors.white70)),
            onPressed: () async {
              // Call the reject service, then update the local state.
              // await RoomService.rejectCoHostRequest(widget.roomID, request.requestId); // Or speaker variant
              setState(onStateChange);
              if (_coHostRequests.isEmpty && _speakerRequests.isEmpty) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              try {
                await onApprove();
                setState(onStateChange); // Update UI by removing the item
                if (_coHostRequests.isEmpty && _speakerRequests.isEmpty) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_coHostRequests.isEmpty && _speakerRequests.isEmpty) {
      return const Center(
        child: Text("No pending requests", style: TextStyle(color: Colors.white70, fontSize: 16)),
      );
    }

    return ListView(
      children: [
        // --- Co-Host Requests Section ---
        if (_coHostRequests.isNotEmpty) ...[
          _buildSectionHeader("Co-Host Requests (${_coHostRequests.length})"),
          ..._coHostRequests.map((request) => _buildRequestTile(
            request: request,
            subtitle: 'Wants to be a co-host',
            onApprove: () => RoomService.approveCoHostRequest(widget.roomID, request.requestId, request.userId),
            onStateChange: () => _coHostRequests.remove(request),
          )).toList(),
          if (_speakerRequests.isNotEmpty) const Divider(color: Colors.white24, height: 1),
        ],

        // --- Speaker Requests Section ---
        if (_speakerRequests.isNotEmpty) ...[
          _buildSectionHeader("Speaker Requests (${_speakerRequests.length})"),
          ..._speakerRequests.map((request) => _buildRequestTile(
            request: request,
            subtitle: 'Wants to join a chair',
            onApprove: () => RoomService.approveSpeakerRequest(widget.roomID, request.requestId, request.userId),
            onStateChange: () => _speakerRequests.remove(request),
          )).toList(),
        ],
      ],
    );
  }
}

// This top-level function is what you'll call from your main UI file.
// It keeps the `showModalBottomSheet` call separate from the content widget.
void showAllRequestsBottomSheet(BuildContext context, {
  required List<dynamic> coHostRequests,
  required List<dynamic> speakerRequests,
  required String roomID,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    // Use the new widget as the content
    builder: (context) => RequestsBottomSheet(
      initialCoHostRequests: coHostRequests,
      initialSpeakerRequests: speakerRequests,
      roomID: roomID,
    ),
  );
}