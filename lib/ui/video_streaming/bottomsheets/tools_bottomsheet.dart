import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/remote/firebase/video_room_services.dart';
import 'invite_pk_bottomsheet.dart';
import 'share_bottomsheet.dart';

class _ToolItem {
  final String label;
  final IconData icon;
  final Color iconBgColor;

  _ToolItem({required this.label, required this.icon, required this.iconBgColor});
}

final List<_ToolItem> _hostTools = [
  _ToolItem(label: 'Share', icon: Icons.share, iconBgColor: Colors.blue.shade700),
  _ToolItem(label: 'Inbox', icon: CupertinoIcons.mail_solid, iconBgColor: Colors.red.shade700),
  _ToolItem(label: 'Speaker', icon: CupertinoIcons.speaker_2_fill, iconBgColor: Colors.blue.shade600),
  _ToolItem(label: 'Funny voice', icon: Icons.tag_faces_outlined, iconBgColor: Colors.purple.shade600),
  _ToolItem(label: 'Room skin', icon: Icons.color_lens_outlined, iconBgColor: Colors.teal.shade600),
  _ToolItem(label: 'Notice', icon: Icons.campaign_outlined, iconBgColor: Colors.indigo.shade600),
  _ToolItem(label: 'Play music', icon: Icons.music_note_outlined, iconBgColor: Colors.pink.shade600),
  _ToolItem(label: 'Games', icon: Icons.games_outlined, iconBgColor: Colors.green.shade700),
  _ToolItem(label: 'Block', icon: Icons.block, iconBgColor: Colors.grey.shade700),
  _ToolItem(label: 'Voice Control', icon: Icons.record_voice_over_outlined, iconBgColor: Colors.lightBlue.shade700),
];

final List<_ToolItem> _guestTools = [
  _ToolItem(label: 'Share', icon: Icons.share, iconBgColor: Colors.blue.shade700),
  _ToolItem(label: 'Inbox', icon: CupertinoIcons.mail_solid, iconBgColor: Colors.red.shade700),
  _ToolItem(label: 'Speaker', icon: CupertinoIcons.speaker_2_fill, iconBgColor: Colors.blue.shade600),
  _ToolItem(label: 'Games', icon: Icons.games_outlined, iconBgColor: Colors.green.shade700),
];

class ToolsBottomSheet extends StatelessWidget {
  final String currentRoomId;
  final bool isHost;
  final String hostName;

  const ToolsBottomSheet({super.key, required this.currentRoomId, required this.isHost, this.hostName = "Host"});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Tools',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isHost ? _hostTools.length : _guestTools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final tool = isHost ? _hostTools[index] : _guestTools[index];

                  VoidCallback onTapLogic;
                  if (tool.label == 'Share') {
                    onTapLogic = () {
                      Navigator.pop(context);
                      showShareBottomSheet(context, currentRoomId, hostName, RoomType.video);
                    };
                  } else {
                    onTapLogic = () {
                      print("Tapped on ${tool.label}");
                      Navigator.pop(context);
                    };
                  }

                  return _buildToolButton(
                    icon: tool.icon,
                    label: tool.label,
                    iconBgColor: tool.iconBgColor,
                    onTap: onTapLogic,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBgColor),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showToolsBottomSheet(
  BuildContext context, {
  required String currentRoomId,
  required bool isHost,
  String hostName = "Host",
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return ToolsBottomSheet(currentRoomId: currentRoomId, isHost: isHost, hostName: hostName);
    },
  );
}
