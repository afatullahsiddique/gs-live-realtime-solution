import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/remote/firebase/live_streaming_services.dart';
import '../../streaming/bottomsheets/play_music_bottomsheet.dart';
import '../../video_streaming/bottomsheets/invite_pk_bottomsheet.dart';
import '../../video_streaming/bottomsheets/share_bottomsheet.dart';

class _ToolItem {
  final String label;
  final IconData icon;
  final Color iconBgColor;

  _ToolItem({required this.label, required this.icon, required this.iconBgColor});
}

final List<_ToolItem> _hostTools = [
  _ToolItem(label: 'Share', icon: Icons.share, iconBgColor: Colors.blue.shade700),
  _ToolItem(label: 'Inbox', icon: CupertinoIcons.mail_solid, iconBgColor: Colors.red.shade700),
  _ToolItem(label: 'Invite PK', icon: Icons.people_outline, iconBgColor: Colors.orange.shade700),
  _ToolItem(label: 'Speaker', icon: CupertinoIcons.speaker_2_fill, iconBgColor: Colors.blue.shade600),
  _ToolItem(label: 'Funny voice', icon: Icons.tag_faces_outlined, iconBgColor: Colors.purple.shade600),
  _ToolItem(label: 'Room skin', icon: Icons.color_lens_outlined, iconBgColor: Colors.teal.shade600),
  _ToolItem(label: 'Notice', icon: Icons.campaign_outlined, iconBgColor: Colors.indigo.shade600),
  _ToolItem(label: 'Play music', icon: Icons.music_note_outlined, iconBgColor: Colors.pink.shade600),
  _ToolItem(label: 'Games', icon: Icons.games_outlined, iconBgColor: Colors.green.shade700),
  _ToolItem(label: 'Random PK', icon: Icons.shuffle, iconBgColor: Colors.deepOrange.shade600),
  _ToolItem(label: 'Block', icon: Icons.block, iconBgColor: Colors.grey.shade700),
  _ToolItem(label: 'Voice Control', icon: Icons.record_voice_over_outlined, iconBgColor: Colors.lightBlue.shade700),
];

final List<_ToolItem> _guestTools = [
  _ToolItem(label: 'Share', icon: Icons.share, iconBgColor: Colors.blue.shade700),
  _ToolItem(label: 'Inbox', icon: CupertinoIcons.mail_solid, iconBgColor: Colors.red.shade700),
  _ToolItem(label: 'Speaker', icon: CupertinoIcons.speaker_2_fill, iconBgColor: Colors.blue.shade600),
  _ToolItem(label: 'Games', icon: Icons.games_outlined, iconBgColor: Colors.green.shade700),
];

class LiveToolsBottomSheet extends StatelessWidget {
  final List<PKInvite> pendingInvites;
  final String currentRoomId;
  final bool isHost;
  final String hostName;
  final MusicPlayerManager musicManager;

  const LiveToolsBottomSheet({
    super.key,
    required this.pendingInvites,
    required this.currentRoomId,
    required this.isHost,
    this.hostName = "Host",
    required this.musicManager,
  });

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
                  if (tool.label == 'Invite PK') {
                    onTapLogic = () {
                      Navigator.pop(context);
                      showInvitePKBottomSheet(context, pendingInvites: pendingInvites, currentRoomId: currentRoomId);
                    };
                  } else if (tool.label == 'Play music') {
                    onTapLogic = () {
                      Navigator.pop(context);
                      showPlayMusicBottomSheet(context, musicManager: musicManager, isHost: isHost);
                    };
                  } else if (tool.label == 'Share') {
                    onTapLogic = () {
                      Navigator.pop(context);
                      showShareBottomSheet(context, currentRoomId, hostName, RoomType.live);
                    };
                  } else if (tool.label == 'Random PK') {
                    onTapLogic = () async {
                      final selectedMinutes = await _showRandomPKConfirmDialog(context);
                      if (selectedMinutes != null) {
                        await _sendRandomPKInvite(context, currentRoomId, selectedMinutes);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
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

  Future<int?> _showRandomPKConfirmDialog(BuildContext context) {
    int selectedMinutes = 5;

    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2d1b2b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Random PK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Are you sure you want to send a random PK invitation?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Duration',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 15, 20].map((minutes) {
                      final isSelected = selectedMinutes == minutes;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMinutes = minutes;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Colors.pink : Colors.white24, width: 1.5),
                          ),
                          child: Text(
                            '$minutes min',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(selectedMinutes),
                  child: const Text('Send', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendRandomPKInvite(BuildContext context, String currentRoomId, int durationInMinutes) async {
    try {
      await LiveStreamService.sendRandomPKInvite(senderRoomId: currentRoomId, durationInMinutes: durationInMinutes);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Random PK invite sent!'), backgroundColor: Colors.pink));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send random PK invite: $e'), backgroundColor: Colors.red));
      }
      rethrow;
    }
  }
}

void showLiveToolsBottomSheet(
  BuildContext context, {
  required List<PKInvite> pendingInvites,
  required String currentRoomId,
  required bool isHost,
  String hostName = "Host",
  required MusicPlayerManager musicManager, // Add this parameter
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return LiveToolsBottomSheet(
        pendingInvites: pendingInvites,
        currentRoomId: currentRoomId,
        isHost: isHost,
        hostName: hostName,
        musicManager: musicManager, // Pass it to the widget
      );
    },
  );
}
