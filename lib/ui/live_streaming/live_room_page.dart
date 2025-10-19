import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../data/remote/firebase/live_streaming_services.dart';
import '../../navigation/routes.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';

// --- MODELS (kept in-file for simplicity) ---

class LiveStreamParticipant {
  final String userId;
  final String userName;
  final String? userPicture;
  final bool isMuted;
  final bool isCameraOn; // Host uses this, guests will be false

  LiveStreamParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.isMuted,
    required this.isCameraOn,
  });

  factory LiveStreamParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStreamParticipant(
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

// --- PAGE ---

class LiveStreamPage extends StatefulWidget {
  final String roomID;
  final bool isHost;

  const LiveStreamPage({super.key, required this.roomID, required this.isHost});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
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
  List<LiveStreamParticipant> _participants = [];
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
        LiveStreamService.deleteRoom(widget.roomID);
      } else {
        if (_isJoined) {
          LiveStreamService.leaveRoom(widget.roomID);
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
      // Host needs camera, guests only need mic
      final permissions = widget.isHost ? [Permission.microphone, Permission.camera] : [Permission.microphone];
      if (!await _checkPermissions(permissions)) {
        if (mounted) context.pop();
        return;
      }

      final roomDoc = await LiveStreamService.getRoomInfo(widget.roomID);
      if (!roomDoc.exists) {
        if (mounted) context.pop();
        return;
      }
      roomData = roomDoc.data() as Map<String, dynamic>;

      await _finishInitialization();
    } catch (e) {
      debugPrint('Error initializing live stream: $e');
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

    // Host turns on mic and camera
    // Guests only turn on mic (if they are approved)
    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().turnCameraOn(widget.isHost); // Only host will have camera on
    ZegoUIKit().setAudioOutputToSpeaker(true);

    _setupListeners();
    setState(() => _isInitialized = true);
  }

  void _setupListeners() {
    _roomSubscription = LiveStreamService.getRoomStream(widget.roomID).listen((doc) {
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

    _participantsSubscription = LiveStreamService.getRoomParticipants(widget.roomID).listen((snapshot) {
      if (mounted) {
        final newParticipants = snapshot.docs.map((doc) => LiveStreamParticipant.fromFirestore(doc)).toList();
        final currentUser = _auth.currentUser!;

        final isNowJoined = newParticipants.any((p) => p.userId == currentUser.uid);

        if (isNowJoined && !_isJoined) {
          debugPrint("Join request approved! Starting local audio stream.");
          ZegoUIKit().turnMicrophoneOn(true);
          // Guests DO NOT turn on camera
          // ZegoUIKit().turnCameraOn(true);
        }

        setState(() {
          _participants = newParticipants;
          _isJoined = isNowJoined;
        });
      }
    });

    if (widget.isHost) {
      _joinRequestsSubscription = LiveStreamService.getJoinRequestsStream(widget.roomID).listen((snapshot) {
        if (mounted) {
          setState(() => _joinRequests = snapshot.docs.map((doc) => JoinRequest.fromFirestore(doc)).toList());
        }
      });
    }
  }

  Future<bool> _checkPermissions(List<Permission> permissions) async {
    await permissions.request();
    for (final permission in permissions) {
      if (!(await permission.status).isGranted) {
        return false;
      }
    }
    return true;
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
          'Exit Stream',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text('Do you want to exit the live stream?', style: TextStyle(color: Colors.white70)),
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
          children: [
            // --- Layer 1: Video Feed (or Loading) ---
            Positioned.fill(
              child: _isInitialized
                  ? _buildVideoLayout()
                  : Container(
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
                SafeArea(
                  top: false, // Only apply padding to the bottom.
                  child: _buildChatInput(),
                ),
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
                  showLiveStreamParticipantsBottomSheet(
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

  // --- WIDGET FOR HOST VIDEO ---
  Widget _buildHostVideo(LiveStreamParticipant host) {
    if (host.isCameraOn) {
      final zegoUser = ZegoUIKit().getUser(host.userId);
      if (zegoUser != null) {
        return ClipRect(child: ZegoAudioVideoView(user: zegoUser));
      }
    }
    // Fallback for camera off
    return ClipRect(
      child: SizedBox.expand(
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                host.userPicture != null && host.userPicture!.isNotEmpty ? NetworkImage(host.userPicture!) : null,
                child: host.userPicture == null || host.userPicture!.isEmpty
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

  // --- WIDGET FOR GUEST AVATAR ---
  Widget _buildGuestAvatar(LiveStreamParticipant guest) {
    // Define your desired border radius
    final borderRadius = BorderRadius.circular(10.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: 80,
        height: 80,
        // Use ClipRRect to enforce the rounded corners on the Stack
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand, // Make sure stack children fill the 80x80 space
            children: [
              // Layer 1: Background Image or Icon
              Container(
                decoration: BoxDecoration(
                  // Use DecorationImage for the background
                  image: (guest.userPicture != null && guest.userPicture!.isNotEmpty)
                      ? DecorationImage(
                    image: NetworkImage(guest.userPicture!),
                    fit: BoxFit.cover,
                  )
                      : null,
                  // Fallback color if no image
                  color: Colors.grey.shade800,
                ),
                // Show icon only if there is no image
                child: (guest.userPicture == null || guest.userPicture!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),

              // Layer 2: Mute Icon Overlay
              if (guest.isMuted)
                Container(
                  // This container will be clipped by the parent ClipRRect
                  color: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.mic_off, color: Colors.white, size: 30),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODIFIED: New Video Layout ---
  Widget _buildVideoLayout() {
    final String hostId = roomData['hostId'];
    LiveStreamParticipant? host;
    final List<LiveStreamParticipant> guests = [];

    for (final p in _participants) {
      if (p.userId == hostId) {
        host = p;
      } else {
        guests.add(p);
      }
    }

    // Use a Stack to overlay guest avatars on top of the host's video
    return Stack(
      children: [
        // Layer 1: Host Video (full screen)
        Positioned.fill(
          child: host != null
              ? _buildHostVideo(host)
              : Container(
            color: Colors.black,
            child: const Center(
              child: Text('Waiting for host...', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        // Layer 2: Guest Avatars (top-left)
        Positioned(
          top: 180, // Below the AppBar
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: guests.map((guest) => _buildGuestAvatar(guest)).toList(),
          ),
        ),
      ],
    );
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
              await LiveStreamService.requestToJoin(widget.roomID);
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
                  'Join Audio', // Changed text
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
    // This is identical to the video room
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

  // --- MODIFIED: Chat Input ---
  Widget _buildChatInput() {
    LiveStreamParticipant? currentUserParticipant;
    if (_isJoined) {
      try {
        currentUserParticipant = _participants.firstWhere((p) => p.userId == _auth.currentUser!.uid);
      } catch (e) {
        currentUserParticipant = null;
      }
    }

    final bool isCurrentlyMuted = currentUserParticipant?.isMuted ?? true;
    final bool isCameraOn = currentUserParticipant?.isCameraOn ?? false; // Only relevant for host
    final int totalRequests = _joinRequests.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Host: Show join request button
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  showLiveStreamJoinRequestsBottomSheet(
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
            // Guests: Show "Leave Call" button
            if (!widget.isHost)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      ZegoUIKit().turnMicrophoneOn(false);
                      await LiveStreamService.leaveRoom(widget.roomID);
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
            // All joined participants: Show Mute button
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  final newMuteState = !isCurrentlyMuted;
                  LiveStreamService.toggleMuteState(widget.roomID, newMuteState);
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
            // **CHANGE**: Only Host sees the Camera button
            if (widget.isHost)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    final newCameraState = !isCameraOn;
                    LiveStreamService.toggleCameraState(widget.roomID, newCameraState);
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
          // Chat text field
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
          // Send button
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