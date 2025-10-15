import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../navigation/routes.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';
import 'bottomsheets/room_settings_bottomsheet.dart';

// ... (CoHostRequest, SpeakerRequest, RoomParticipant, ChatMessage classes are unchanged)
class CoHostRequest {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;

  CoHostRequest({required this.requestId, required this.userId, required this.userName, this.userPicture});

  factory CoHostRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoHostRequest(
      requestId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPicture: data['userPicture'],
    );
  }
}

class SpeakerRequest {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;

  SpeakerRequest({required this.requestId, required this.userId, required this.userName, this.userPicture});

  factory SpeakerRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpeakerRequest(
      requestId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPicture: data['userPicture'],
    );
  }
}

class RoomParticipant {
  final String userId;
  final String userName;
  final String? userPicture;
  final int seatNo; // -1: listener, 0: host, >0: speaker seat
  final bool isCoHost;
  final bool isMuted;
  final ZegoUIKitUser? zegoUser; // Holds live Zego data for sound level, etc.

  RoomParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.seatNo,
    required this.isCoHost,
    required this.isMuted,
    this.zegoUser,
  });

  factory RoomParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomParticipant(
      userId: data['userId'] ?? doc.id,
      userName: data['userName'] ?? 'Unknown',
      userPicture: data.containsKey('userPicture') ? data['userPicture'] : null,
      seatNo: data['seatNo'] ?? -1,
      isCoHost: data['isCoHost'] ?? false,
      isMuted: data['isMuted'] ?? true,
    );
  }

  RoomParticipant copyWith({ZegoUIKitUser? zegoUser}) {
    return RoomParticipant(
      userId: this.userId,
      userName: this.userName,
      userPicture: this.userPicture,
      seatNo: this.seatNo,
      isCoHost: this.isCoHost,
      isMuted: this.isMuted,
      zegoUser: zegoUser ?? this.zegoUser,
    );
  }
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.username, required this.message, required this.timestamp});
}

class AudioRoomPage extends StatefulWidget {
  final String roomID;
  final bool isHost;

  const AudioRoomPage({super.key, required this.roomID, required this.isHost});

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream Subscriptions
  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _speakerRequestsSubscription;
  StreamSubscription? _coHostRequestsSubscription;

  // State Variables
  late Map<String, dynamic> roomData;
  List<RoomParticipant> _participants = [];
  List<ChatMessage> _messages = [];
  List<SpeakerRequest> _speakerRequests = [];
  List<CoHostRequest> _coHostRequests = [];
  int _participantCount = 0;
  bool _isInitialized = false;
  bool _isMoveAllowed = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();
    _participantsSubscription?.cancel();
    _speakerRequestsSubscription?.cancel();
    _coHostRequestsSubscription?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();

    if (_isInitialized) {
      if (widget.isHost) {
        RoomService.deleteRoom(widget.roomID);
      } else {
        RoomService.leaveRoom(widget.roomID);
      }
      ZegoUIKit().leaveRoom();
      ZegoUIKit().logout();
      ZegoUIKit().uninit();
    }
    super.dispose();
  }

  // ... (All initialization and dialog logic is unchanged)
  Future<void> _initialize() async {
    try {
      final roomDoc = await RoomService.getRoomInfo(widget.roomID);
      if (!roomDoc.exists) {
        if (mounted) context.pop();
        return;
      }
      roomData = roomDoc.data() as Map<String, dynamic>;

      final bool isLocked = roomData['isLocked'] ?? false;

      if (isLocked && !widget.isHost) {
        final bool? passwordCorrect = await _showPasswordDialog();
        if (passwordCorrect == true) {
          await _finishInitialization();
        }
      } else {
        await _finishInitialization();
      }
    } catch (e) {
      debugPrint('Error initializing audio room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        context.pop();
      }
    }
  }

  Future<void> _finishInitialization() async {
    if (!await _checkAudioPermissions()) {
      if (mounted) context.pop();
      return;
    }

    await ZegoUIKit().init(
      appID: 1738777063, // Your App ID
      appSign: "1b5dbd4c4dac51d753a6a4eb7563490006a11a161c5133a4bb2f4727d5e34550", // Your App Sign
      scenario: ZegoScenario.Default,
    );

    final currentUser = _auth.currentUser!;
    ZegoUIKit().login(currentUser.uid, currentUser.displayName ?? "Unknown");
    await ZegoUIKit().joinRoom(widget.roomID);

    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().setAudioOutputToSpeaker(true);
    ZegoUIKit().startPlayAllAudioVideo();

    if (!widget.isHost) {
      await RoomService.joinRoom(widget.roomID);
      _sendJoinMessage();
    }

    _setupListeners();
    setState(() => _isInitialized = true);
  }

  Future<bool?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final completer = Completer<bool?>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2d1b2b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Password Required', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This room is locked. Please enter the password to join.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter password",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      errorText: errorText,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (context.canPop()) context.pop();
                    completer.complete(false);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Enter', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (passwordController.text == roomData['password']) {
                      Navigator.of(dialogContext).pop();
                      completer.complete(true);
                    } else {
                      setState(() => errorText = 'Incorrect password. Please try again.');
                      passwordController.clear();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    return completer.future;
  }

  void _setupListeners() {
    _roomSubscription = RoomService.getRoomStream(widget.roomID).listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          roomData = doc.data() as Map<String, dynamic>;
          _participantCount = roomData['participantCount'] ?? 0;
          _isMoveAllowed = roomData['isMoveAllowed'] ?? true;
        });
      } else {
        if (mounted) context.pop();
      }
    });

    _messageSubscription = ZegoUIKit().getInRoomMessageStream().listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(username: message.user.name, message: message.message, timestamp: DateTime.now()));
          _scrollToBottom();
        });
      }
    });

    _participantsSubscription = RoomService.getRoomParticipants(widget.roomID).listen((snapshot) {
      final zegoUsers = ZegoUIKit().getAllUsers();
      final updatedParticipants = snapshot.docs.map((doc) {
        final participant = RoomParticipant.fromFirestore(doc);
        try {
          final zegoUser = zegoUsers.firstWhere((user) => user.id == participant.userId);
          return participant.copyWith(zegoUser: zegoUser);
        } catch (e) {
          return participant;
        }
      }).toList();

      if (mounted) setState(() => _participants = updatedParticipants);
    });

    if (widget.isHost) {
      _speakerRequestsSubscription = RoomService.getSpeakerRequestsStream(widget.roomID).listen((snapshot) {
        if (mounted) {
          setState(() => _speakerRequests = snapshot.docs.map((doc) => SpeakerRequest.fromFirestore(doc)).toList());
        }
      });
      _coHostRequestsSubscription = RoomService.getCoHostRequestsStream(widget.roomID).listen((snapshot) {
        if (mounted) {
          setState(() => _coHostRequests = snapshot.docs.map((doc) => CoHostRequest.fromFirestore(doc)).toList());
        }
      });
    }
  }

  Future<void> _showSetPasswordDialog() async {
    final passwordController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2d1b2b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Set Room Password', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new password",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Set Password', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) return;

                Navigator.of(dialogContext).pop();
                try {
                  await RoomService.setOrChangeRoomPassword(widget.roomID, password);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password has been set.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error setting password: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPasswordManagementDialog() async {
    final bool isCurrentlyLocked = roomData['isLocked'] ?? false;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isCurrentlyLocked) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2d1b2b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Manage Password', style: TextStyle(color: Colors.white)),
          content: const Text('This room is currently password protected.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Remove Password', style: TextStyle(color: Colors.orangeAccent)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await RoomService.removeRoomPassword(widget.roomID);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Room is now public.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error removing password: $e')));
                }
              },
            ),
            TextButton(
              child: const Text('Change Password', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showSetPasswordDialog();
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    } else {
      _showSetPasswordDialog();
    }
  }

  Future<bool> _checkAudioPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b), Color(0xFF4a2c4a), Color(0xFFff6b9d)],
              stops: [0.0, 0.3, 0.6, 0.8, 1.0],
            ),
          ),
          child: SafeArea(
            child: _isInitialized
                ? Column(
                    children: [
                      _buildAppBar(),
                      Column(children: [const SizedBox(height: 10), _buildStreamerProfile(), _buildSeatsGrid()]),
                      // MODIFIED: Wrapped the chat section in a Stack to allow for the button overlay
                      Expanded(
                        child: Stack(
                          children: [
                            _buildChatSection(),
                            _buildJoinCallOverlay(), // The new button
                          ],
                        ),
                      ),
                      _buildChatInput(),
                    ],
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.pink)),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
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
              showParticipantsBottomSheet(context, participants: _participants, currentUserId: _auth.currentUser!.uid);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
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
          if (widget.isHost)
            IconButton(
              icon: Icon((roomData['isLocked'] ?? false) ? Icons.lock : Icons.lock_open, color: Colors.white, size: 24),
              onPressed: _showPasswordManagementDialog,
              tooltip: 'Room Security',
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, size: 28, color: Colors.grey),
            onPressed: _showExitConfirmationDialog,
            tooltip: 'Exit Room',
          ),
        ],
      ),
    );
  }

  // ... (Streamer Profile, Seats Grid, etc. are unchanged)
  Widget _buildStreamerProfile() {
    RoomParticipant? host;
    try {
      host = _participants.firstWhere((p) => p.userId == roomData['hostId']);
    } catch (e) {
      host = null;
    }

    RoomParticipant? coHost;
    try {
      coHost = _participants.firstWhere((p) => p.isCoHost && p.userId != roomData['hostId'] && p.seatNo <= 0);
    } catch (e) {
      coHost = null;
    }

    Widget buildStreamerSeat({
      required String? imageUrl,
      required String name,
      required bool isMuted,
      bool isHost = true,
    }) {
      final double size = 65.0;
      return Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade300, Colors.pink.shade500, Colors.purple.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 8)),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
              if (isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.mic_off, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: isHost ? Colors.pink : Colors.white,
              fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildStreamerSeat(
            imageUrl: roomData['hostPicture'],
            name: roomData['hostName'],
            isMuted: host?.isMuted ?? true,
            isHost: true,
          ),
          const SizedBox(width: 30),
          if (coHost != null)
            GestureDetector(
              onTap: coHost.userId != _auth.currentUser!.uid
                  ? null
                  : () async {
                      try {
                        await RoomService.stepDownFromCoHost(widget.roomID);
                        ZegoUIKit().turnMicrophoneOn(false);
                      } catch (e) {
                        debugPrint("Error stepping down from co-host: $e");
                      }
                    },
              child: buildStreamerSeat(
                imageUrl: coHost.userPicture,
                name: coHost.userName,
                isMuted: coHost.isMuted,
                isHost: false,
              ),
            )
          else
            Builder(
              builder: (context) {
                final currentUserParticipant = _participants.firstWhere(
                  (p) => p.userId == _auth.currentUser!.uid,
                  orElse: () => RoomParticipant(userId: '', userName: '', seatNo: -1, isCoHost: false, isMuted: true),
                );
                final bool canRequestCoHost = !widget.isHost && !currentUserParticipant.isCoHost;
                return GestureDetector(
                  onTap: !canRequestCoHost
                      ? null
                      : () async {
                          try {
                            await RoomService.requestToBeCoHost(widget.roomID);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Co-host request sent. Please wait for host approval.'),
                                  backgroundColor: Colors.pink,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("Error requesting to be co-host: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                            }
                          }
                        },
                  child: Column(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.pink.shade400.withOpacity(0.8), width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chair_outlined,
                            color: canRequestCoHost ? Colors.white : Colors.grey.shade700,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium',
                        style: TextStyle(color: canRequestCoHost ? Colors.white : Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid() {
    const int seatCount = 12;
    final String currentUserId = _auth.currentUser!.uid;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: seatCount,
      itemBuilder: (context, index) {
        final seatNo = index + 1;
        RoomParticipant? participantOnSeat;
        try {
          participantOnSeat = _participants.firstWhere((p) => p.seatNo == seatNo);
        } catch (e) {
          participantOnSeat = null;
        }

        if (participantOnSeat != null) {
          return _buildOccupiedSeat(participantOnSeat, isCurrentUser: participantOnSeat.userId == currentUserId);
        } else {
          return _buildEmptySeat(seatNo);
        }
      },
    );
  }

  Widget _buildEmptySeat(int seatNo) {
    final currentUser = _auth.currentUser!;
    RoomParticipant? currentUserParticipant;
    try {
      currentUserParticipant = _participants.firstWhere((p) => p.userId == currentUser.uid);
    } catch (e) {
      currentUserParticipant = null;
    }

    final bool canInteract = !widget.isHost && currentUserParticipant != null;
    final bool isListener = canInteract && currentUserParticipant.seatNo == -1 && !currentUserParticipant.isCoHost;
    final bool isSpeakerOrCoHost =
        canInteract && (currentUserParticipant.seatNo > 0 || currentUserParticipant.isCoHost);

    return GestureDetector(
      onTap: () async {
        if (!canInteract) return;
        try {
          if (isListener) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap the \'Join Call\' button to request a seat.'),
                backgroundColor: Colors.pink,
              ),
            );
          } else if (isSpeakerOrCoHost) {
            if (_isMoveAllowed) {
              await RoomService.moveSeat(widget.roomID, seatNo);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('The host has disabled moving between seats.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Error with seat action: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pink.withOpacity(0.2), width: 2),
            ),
            child: Icon(Icons.event_seat, color: canInteract ? Colors.pink : Colors.grey.shade800, size: 28),
          ),
          const SizedBox(height: 4),
          Text('Seat $seatNo', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildOccupiedSeat(RoomParticipant participant, {required bool isCurrentUser}) {
    final canLeaveSeat = isCurrentUser && !widget.isHost;
    return GestureDetector(
      onTap: !canLeaveSeat
          ? null
          : () async {
              try {
                await RoomService.leaveSeat(widget.roomID);
                ZegoUIKit().turnMicrophoneOn(false);
              } catch (e) {
                debugPrint("Error leaving seat: $e");
              }
            },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: participant.zegoUser == null
                    ? _buildAvatar(participant)
                    : StreamBuilder<double>(
                        stream: participant.zegoUser!.soundLevel,
                        builder: (context, snapshot) {
                          final isSpeaking = (snapshot.data ?? 0) > 10;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildAvatar(participant, isSpeaking: isSpeaking),
                              if (isSpeaking)
                                Transform.scale(
                                  scale: 1.35,
                                  child: SVGAEasyPlayer(assetsName: "assets/svga/talking.svga", fit: BoxFit.cover),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              if (participant.isMuted)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.mic_off, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              participant.userName,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(RoomParticipant participant, {bool isSpeaking = false}) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink.withOpacity(isSpeaking ? 0.8 : 0.4), width: 2),
      ),
      child: ClipOval(
        child: participant.userPicture != null && participant.userPicture!.isNotEmpty
            ? Image.network(
                participant.userPicture!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatarContent(participant.userName),
              )
            : _defaultAvatarContent(participant.userName),
      ),
    );
  }

  Widget _defaultAvatarContent(String name) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : "?",
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  // NEW WIDGET: The "Join Call" button as an overlay for guests.
  Widget _buildJoinCallOverlay() {
    final String currentUserId = _auth.currentUser!.uid;
    RoomParticipant? currentUserParticipant;
    try {
      currentUserParticipant = _participants.firstWhere((p) => p.userId == currentUserId);
    } catch (e) {
      currentUserParticipant = null;
    }
    final bool isListener =
        !widget.isHost &&
        (currentUserParticipant == null || (currentUserParticipant.seatNo == -1 && !currentUserParticipant.isCoHost));

    return Visibility(
      visible: isListener,
      child: Positioned(
        bottom: 8,
        right: 24,
        child: GestureDetector(
          onTap: () async {
            try {
              await RoomService.requestToBeSpeaker(widget.roomID);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request sent. Please wait for host approval.'),
                    backgroundColor: Colors.pink,
                  ),
                );
              }
            } catch (e) {
              debugPrint("Error requesting to be speaker: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border.all(color: Colors.pink, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withOpacity(0.2)),
      child: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      "Any sexual or violation content is strictly prohibited. All violator will be banned. Do not expose your personal info such phone or location.",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }

          final messageIndex = index - 1;
          final m = _messages[messageIndex];

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
                  child: Text(m.message, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput() {
    final String currentUserId = _auth.currentUser!.uid;
    RoomParticipant? currentUserParticipant;
    try {
      currentUserParticipant = _participants.firstWhere((p) => p.userId == currentUserId);
    } catch (e) {
      currentUserParticipant = null;
    }

    final bool isSpeakerOrCoHost =
        widget.isHost ||
        (currentUserParticipant != null && (currentUserParticipant.isCoHost || currentUserParticipant.seatNo > 0));

    final bool isCurrentlyMuted = currentUserParticipant?.isMuted ?? true;
    final int totalRequests = _coHostRequests.length + _speakerRequests.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () => showRoomSettingsBottomSheet(context, roomId: widget.roomID, isMoveAllowed: _isMoveAllowed),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: const Icon(CupertinoIcons.settings, color: Colors.white),
                ),
              ),
            ),
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () => showAllRequestsBottomSheet(
                  context,
                  coHostRequests: _coHostRequests,
                  speakerRequests: _speakerRequests,
                  roomID: widget.roomID,
                ),
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
          if (isSpeakerOrCoHost)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  final newMuteState = !isCurrentlyMuted;
                  RoomService.toggleMuteState(widget.roomID, newMuteState);
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
          // REMOVED: The listener's "Join Call" button was removed from here.
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
        _messages.add(
          ChatMessage(
            username: _auth.currentUser?.displayName ?? "Me",
            message: messageText,
            timestamp: DateTime.now(),
          ),
        );
      });
      _chatController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _sendJoinMessage() async {
    const messageText = "Just joined the room!";
    try {
      await ZegoUIKit().sendInRoomMessage(messageText);
    } catch (e) {
      debugPrint('Error sending join message: $e');
    }
  }
}
