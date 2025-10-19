import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../data/remote/firebase/video_room_services.dart';
import '../../navigation/routes.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';

class VideoParticipant {
  final String userId;
  final String userName;
  final String? userPicture;
  final bool isMuted;
  final bool isCameraOn;

  VideoParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.isMuted,
    required this.isCameraOn,
  });

  factory VideoParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoParticipant(
      userId: data['userId'] ?? doc.id,
      userName: data['userName'] ?? 'Unknown',
      userPicture: data.containsKey('userPicture') ? data['userPicture'] : null,
      isMuted: data['isMuted'] ?? true,
      isCameraOn: data['isCameraOn'] ?? false,
    );
  }
}

class JoinRequest {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;

  JoinRequest({required this.requestId, required this.userId, required this.userName, this.userPicture});

  factory JoinRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      requestId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPicture: data['userPicture'],
    );
  }
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.username, required this.message, required this.timestamp});
}

class VideoRoomPage extends StatefulWidget {
  final String roomID;
  final bool isHost;

  const VideoRoomPage({super.key, required this.roomID, required this.isHost});

  @override
  State<VideoRoomPage> createState() => _VideoRoomPageState();
}

class _VideoRoomPageState extends State<VideoRoomPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream Subscriptions
  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _joinRequestsSubscription;

  // State Variables
  late Map<String, dynamic> roomData;
  List<VideoParticipant> _participants = [];
  List<ChatMessage> _messages = [];
  List<JoinRequest> _joinRequests = [];
  int _participantCount = 0;
  bool _isInitialized = false;
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.isHost;
    _initialize();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();
    _participantsSubscription?.cancel();
    _joinRequestsSubscription?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();

    if (_isInitialized) {
      if (widget.isHost) {
        VideoRoomService.deleteRoom(widget.roomID);
      } else {
        if (_isJoined) {
          VideoRoomService.leaveRoom(widget.roomID);
        }
      }
      ZegoUIKit().leaveRoom();
      ZegoUIKit().logout();
      ZegoUIKit().uninit();
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      if (!await _checkPermissions()) {
        if (mounted) context.pop();
        return;
      }

      final roomDoc = await VideoRoomService.getRoomInfo(widget.roomID);
      if (!roomDoc.exists) {
        if (mounted) context.pop();
        return;
      }
      roomData = roomDoc.data() as Map<String, dynamic>;

      await _finishInitialization();
    } catch (e) {
      debugPrint('Error initializing video room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        context.pop();
      }
    }
  }

  Future<void> _finishInitialization() async {
    await ZegoUIKit().init(
      appID: 1738777063, // Your App ID
      appSign: "1b5dbd4c4dac51d753a6a4eb7563490006a11a161c5133a4bb2f4727d5e34550", // Your App Sign
      scenario: ZegoScenario.Default,
    );

    ZegoUIKit().updateVideoViewMode(true);

    final currentUser = _auth.currentUser!;
    ZegoUIKit().login(currentUser.uid, currentUser.displayName ?? "Unknown");
    await ZegoUIKit().joinRoom(widget.roomID);

    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().turnCameraOn(widget.isHost);
    ZegoUIKit().setAudioOutputToSpeaker(true);

    _setupListeners();
    setState(() => _isInitialized = true);
  }

  void _setupListeners() {
    _roomSubscription = VideoRoomService.getRoomStream(widget.roomID).listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          roomData = doc.data() as Map<String, dynamic>;
          _participantCount = roomData['participantCount'] ?? 0;
        });
      } else {
        if (mounted) context.pop();
      }
    });

    _messageSubscription = ZegoUIKit().getInRoomMessageStream().listen((message) {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(username: message.user.name, message: message.message, timestamp: DateTime.now()),
          );
          _scrollToNewestMessage();
        });
      }
    });

    _participantsSubscription = VideoRoomService.getRoomParticipants(widget.roomID).listen((snapshot) {
      if (mounted) {
        final newParticipants = snapshot.docs.map((doc) => VideoParticipant.fromFirestore(doc)).toList();
        final currentUser = _auth.currentUser!;

        final isNowJoined = newParticipants.any((p) => p.userId == currentUser.uid);

        if (isNowJoined && !_isJoined) {
          debugPrint("Join request approved! Starting local video/audio stream.");
          ZegoUIKit().turnMicrophoneOn(true);
          ZegoUIKit().turnCameraOn(true);
        }

        setState(() {
          _participants = newParticipants;
          _isJoined = isNowJoined;
        });
      }
    });

    if (widget.isHost) {
      _joinRequestsSubscription = VideoRoomService.getJoinRequestsStream(widget.roomID).listen((snapshot) {
        if (mounted) {
          setState(() => _joinRequests = snapshot.docs.map((doc) => JoinRequest.fromFirestore(doc)).toList());
        }
      });
    }
  }

  Future<bool> _checkPermissions() async {
    await [Permission.microphone, Permission.camera].request();
    PermissionStatus micStatus = await Permission.microphone.status;
    PermissionStatus camStatus = await Permission.camera.status;
    return micStatus.isGranted && camStatus.isGranted;
  }

  void _scrollToNewestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(0.0);
      }
    });
  }

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text('Do you want to exit the room?', style: TextStyle(color: Colors.white70)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((shouldExit) {
      if (shouldExit == true) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home.path);
        }
      }
      return shouldExit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmationDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Base color behind the video
        body: Stack(
          // Use a Stack as the main layout
          children: [
            // --- Layer 1: Video Feed (or Loading) ---
            Positioned.fill(
              child: _isInitialized
                  ? _buildVideoLayout()
                  : Container(
                // Background gradient while loading
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b)],
                  ),
                ),
                child: const Center(child: CircularProgressIndicator(color: Colors.pink)),
              ),
            ),

            // --- Layer 2: UI Overlays ---
            // This Column arranges the transparent UI elements on top of the video
            _isInitialized
                ? Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(bottom: 0, left: 0, right: 0, child: _buildChatSection()), // Chat has a gradient
                      _buildJoinCallOverlay(),
                    ],
                  ),
                ),
                // --- MODIFICATION HERE ---
                // Wrapped _buildChatInput() in a SafeArea to avoid the system navigation bar.
                SafeArea(
                  top: false, // Only apply padding to the bottom.
                  child: _buildChatInput(),
                ),
                // --- END MODIFICATION ---
              ],
            )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5), // Dark scrim at the top
            Colors.transparent, // Fades to transparent
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(roomData['hostPicture'] ?? '')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomData["hostName"],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('ID: ${widget.roomID}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showVideoParticipantsBottomSheet(
                    context,
                    participants: _participants,
                    currentUserId: _auth.currentUser!.uid,
                    hostId: roomData['hostId'],
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.person_2_fill, color: Colors.pink, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _participantCount.toString(),
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app_rounded, size: 28, color: Colors.grey),
                onPressed: _showExitConfirmationDialog,
                tooltip: 'Exit Room',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayout() {
    if (_participants.isEmpty) {
      if (widget.isHost) {
        return ClipRect(child: ZegoAudioVideoView(user: ZegoUIKit().getUser(_auth.currentUser!.uid)));
      }
      return const Center(
        child: Text('Waiting for participants...', style: TextStyle(color: Colors.white)),
      );
    }

    Widget buildZegoView(VideoParticipant participant) {
      if (participant.isCameraOn) {
        final zegoUser = ZegoUIKit().getUser(participant.userId);
        if (zegoUser != null) {
          return ClipRect(child: ZegoAudioVideoView(user: zegoUser));
        }
      }

      return ClipRect(
        child: SizedBox.expand(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: participant.userPicture != null && participant.userPicture!.isNotEmpty
                      ? NetworkImage(participant.userPicture!)
                      : null,
                  child: participant.userPicture == null || participant.userPicture!.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                ),
                const Icon(Icons.videocam_off, color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      );
    }

    switch (_participants.length) {
      case 1:
        return buildZegoView(_participants[0]);
      case 2:
        return Column(
          children: [
            Expanded(child: buildZegoView(_participants[0])),
            Expanded(child: buildZegoView(_participants[1])),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(flex: 2, child: buildZegoView(_participants[0])),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: buildZegoView(_participants[1])),
                  Expanded(child: buildZegoView(_participants[2])),
                ],
              ),
            ),
          ],
        );
      case 4:
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0),
          itemCount: _participants.length,
          itemBuilder: (context, index) {
            return buildZegoView(_participants[index]);
          },
        );
      default:
        return const Center(
          child: Text('Room is full', style: TextStyle(color: Colors.white)),
        );
    }
  }

  Widget _buildJoinCallOverlay() {
    return Visibility(
      visible: !_isJoined && !widget.isHost,
      child: Positioned(
        bottom: 20,
        right: 20,
        child: GestureDetector(
          onTap: () async {
            try {
              await VideoRoomService.requestToJoin(widget.roomID);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request sent. Wait for host approval.'), backgroundColor: Colors.pink),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border.all(color: Colors.pink, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.phone_arrow_up_right, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Join Call',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.6)],
        ),
      ),
      child: ListView.builder(
        reverse: true,
        controller: _chatScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: _messages.length + 1,
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    child: Text(
                      "Any sexual or violation content is strictly prohibited. All violator will be banned. Do not expose your personal info such phone or location.",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            );
          }

          final m = _messages[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade700,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Text(
                        "Lv 1",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      "${m.username}: ",
                      style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 2),
                  child: Text(m.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput() {
    VideoParticipant? currentUserParticipant;
    if (_isJoined) {
      try {
        currentUserParticipant = _participants.firstWhere((p) => p.userId == _auth.currentUser!.uid);
      } catch (e) {
        currentUserParticipant = null;
      }
    }

    final bool isCurrentlyMuted = currentUserParticipant?.isMuted ?? true;
    final bool isCameraOn = currentUserParticipant?.isCameraOn ?? false;
    final int totalRequests = _joinRequests.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  showVideoJoinRequestsBottomSheet(
                    context: context,
                    joinRequests: _joinRequests,
                    roomID: widget.roomID,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                      child: const Icon(CupertinoIcons.person_add_solid, color: Colors.white),
                    ),
                    if (totalRequests > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.pink),
                          child: Text(
                            totalRequests.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_isJoined) ...[
            if (!widget.isHost)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      ZegoUIKit().turnCameraOn(false);
                      ZegoUIKit().turnMicrophoneOn(false);
                      await VideoRoomService.leaveRoom(widget.roomID);
                    } catch (e) {
                      debugPrint("Error leaving call: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leaving call: $e')));
                      }
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 24),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  final newMuteState = !isCurrentlyMuted;
                  VideoRoomService.toggleMuteState(widget.roomID, newMuteState);
                  ZegoUIKit().turnMicrophoneOn(!newMuteState);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: Icon(
                    isCurrentlyMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                    color: isCurrentlyMuted ? Colors.white : Colors.pink,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  final newCameraState = !isCameraOn;
                  VideoRoomService.toggleCameraState(widget.roomID, newCameraState);
                  ZegoUIKit().turnCameraOn(newCameraState);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: Icon(
                    isCameraOn ? CupertinoIcons.videocam_fill : Icons.videocam_off,
                    color: isCameraOn ? Colors.pink : Colors.white,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox.shrink(),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty) return;

    try {
      await ZegoUIKit().sendInRoomMessage(messageText);
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            username: _auth.currentUser?.displayName ?? "Me",
            message: messageText,
            timestamp: DateTime.now(),
          ),
        );
      });
      _chatController.clear();
      _scrollToNewestMessage();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}