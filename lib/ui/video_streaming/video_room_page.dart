import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../core/widgets/auto_scroll_text.dart';
import '../../data/remote/firebase/profile_services.dart';
import '../../data/remote/firebase/video_room_services.dart';
import '../../navigation/routes.dart';
import 'bottomsheets/invite_pk_bottomsheet.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/profile_info_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';
import 'bottomsheets/tools_bottomsheet.dart';
import 'package:collection/collection.dart';

class VideoParticipant {
  final String userId;
  final String userName;
  final String? userPicture;
  final bool isMuted;
  final bool isCameraOn;
  final bool onCall;

  VideoParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.isMuted,
    required this.isCameraOn,
    required this.onCall,
  });

  factory VideoParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoParticipant(
      userId: data['userId'] ?? doc.id,
      userName: data['userName'] ?? 'Unknown',
      userPicture: data.containsKey('userPicture') ? data['userPicture'] : null,
      isMuted: data['isMuted'] ?? true,
      isCameraOn: data['isCameraOn'] ?? false,
      onCall: data['onCall'] ?? false,
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
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.userId, required this.username, required this.message, required this.timestamp});
}

class VideoRoomPage extends StatefulWidget {
  final String roomID;
  final bool isHost;

  const VideoRoomPage({super.key, required this.roomID, required this.isHost});

  @override
  State<VideoRoomPage> createState() => _VideoRoomPageState();
}

class _VideoRoomPageState extends State<VideoRoomPage> with SingleTickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _joinRequestsSubscription;
  StreamSubscription? _pkInvitesSubscription;
  StreamSubscription? _sentPKInvitesSubscription;
  StreamSubscription? _opponentParticipantsSubscription;

  // State Variables
  late Map<String, dynamic> roomData;
  List<VideoParticipant> _participants = [];
  List<VideoParticipant> _allParticipants = []; // For join animation tracking
  List<ChatMessage> _messages = [];
  List<JoinRequest> _joinRequests = [];
  List<PKInvite> _pendingInvites = [];
  int _participantCount = 0;
  bool _isInitialized = false;
  late bool _isJoined;
  final Set<String> _dialogsShownForInviteIds = {};

  bool _isPKMode = false;
  Map<String, dynamic> _pkState = {};
  List<VideoParticipant> _opponentParticipants = [];

  Timer? _pkTimer;
  String _pkTimerDisplay = "00:00";

  int _pkScoreBlue = 0;
  int _pkScoreRed = 0;

  bool _isStartingPKAnimation = false;

  String _currentUserName = "Me";

  // --- Welcome Animation Vars ---
  Duration welcomeTime = Duration(milliseconds: 3500);
  Timer? _joinAnimationTimer;
  String? _newJoinerName;
  late AnimationController _joinAnimationController;
  late Animation<Offset> _joinAnimationOffset;

  // --- End Welcome Animation Vars ---

  @override
  void initState() {
    super.initState();
    _isJoined = widget.isHost;
    _initialize();

    // --- Welcome Animation Init ---
    _joinAnimationController = AnimationController(duration: welcomeTime, vsync: this);

    _joinAnimationOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(1.5, 0.0),
          end: const Offset(0.0, 0.0),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(0.0, 0.0)), weight: 3.0),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.0, 0.0),
          end: const Offset(-1.5, 0.0),
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 1.0, // 2 parts of the duration
      ),
    ]).animate(_joinAnimationController);
    // --- End Welcome Animation Init ---

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
    _pkInvitesSubscription?.cancel();
    _sentPKInvitesSubscription?.cancel();
    _opponentParticipantsSubscription?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    _pkTimer?.cancel();

    _joinAnimationTimer?.cancel();
    _joinAnimationController.dispose();

    if (_isInitialized) {
      if (widget.isHost) {
        if (_isPKMode && _pkState.containsKey('opponentRoomId')) {
          VideoRoomService.endPKBattle(widget.roomID, _pkState['opponentRoomId']);

          String opponentHostId = _pkState['opponentHostId'] ?? '';
          if (opponentHostId.isNotEmpty) {
            ZegoUIKit().stopPlayAnotherRoomAudioVideo(opponentHostId);
          }
        }
        VideoRoomService.deleteRoom(widget.roomID);
      } else {
        VideoRoomService.leaveRoom(widget.roomID);
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
      appID: 751798122, // Your App ID
      appSign: "ec25b1cfc409394987c89a717dd124dce925283695e2ebc36a37882feda0ef84", // Your App Sign
      scenario: ZegoScenario.Default,
    );

    // This sets the mode for the LOCAL user and users in the SAME room
    ZegoUIKit().updateVideoViewMode(true);

    final currentUser = _auth.currentUser!;

    // --- ADD THIS BLOCK TO FETCH USERNAME ---
    try {
      final userDoc = await ProfileService.getUserProfile(currentUser.uid);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['displayName'] ?? "Unknown";
        });
      } else {
        setState(() {
          _currentUserName = currentUser.displayName ?? "Unknown";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
      setState(() {
        _currentUserName = currentUser.displayName ?? "Unknown"; // Fallback
      });
    }
    // --- END OF BLOCK ---

    ZegoUIKit().login(currentUser.uid, _currentUserName); // <-- USE FETCHED NAME
    await ZegoUIKit().joinRoom(widget.roomID);

    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().turnCameraOn(widget.isHost);
    ZegoUIKit().setAudioOutputToSpeaker(true);

    if (!widget.isHost) {
      try {
        await VideoRoomService.joinRoom(widget.roomID);
      } catch (e) {
        debugPrint("Error joining room as viewer: $e");
      }
      _sendJoinMessage();

      _showJoinAnimation(_currentUserName); // <-- USE FETCHED NAME
    }

    _setupListeners();
    setState(() => _isInitialized = true);
  }

  void _startPKBattleSequence(Map<String, dynamic> newPKState) {
    // Set state immediately for animation to get opponent data and show overlay
    setState(() {
      _pkState = newPKState;
    });

    if (!mounted) return;

    debugPrint("PK Animation finished. Starting PK logic.");

    // Start all the background PK logic
    if (widget.isHost) {
      final hostId = _auth.currentUser!.uid;
      VideoRoomService.demoteAllParticipantsToViewers(widget.roomID, hostId);
    }

    if (widget.isHost && newPKState['role'] == 'sender') {
      String opponentRoomId = newPKState['opponentRoomId'] ?? '';
      String opponentHostId = newPKState['opponentHostId'] ?? '';
      if (opponentRoomId.isNotEmpty && opponentHostId.isNotEmpty) {
        debugPrint("Sender is starting to play opponent's stream: $opponentHostId");
        ZegoUIKit().startPlayAnotherRoomAudioVideo(opponentRoomId, opponentHostId);
        ZegoUIKit().updateVideoViewMode(true);
      }
    }

    // Start the PK Timer
    final Timestamp? pkEndTimeStamp = newPKState['pkEndTime'] as Timestamp?;
    if (pkEndTimeStamp != null) {
      _startPKTimer(pkEndTimeStamp.toDate());
    }

    _opponentParticipantsSubscription?.cancel();
    _opponentParticipantsSubscription = VideoRoomService.getRoomParticipants(newPKState['opponentRoomId']).listen((
      snapshot,
    ) {
      if (mounted) {
        final newOpponentParticipants = snapshot.docs.map((doc) => VideoParticipant.fromFirestore(doc)).toList();
        setState(() {
          _opponentParticipants = newOpponentParticipants.where((p) => p.onCall == true).toList();
        });
      }
    });

    // Final state update to switch UI from animation to PK layout
    setState(() async {
      _isPKMode = true;
      await Future.delayed(Duration(seconds: 1));
      _isStartingPKAnimation = true;
      await Future.delayed(Duration(seconds: 3));
      _isStartingPKAnimation = false;
    });
  }

  void _setupListeners() {
    _roomSubscription = VideoRoomService.getRoomStream(widget.roomID).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          roomData = data;
          _participantCount = roomData['participantCount'] ?? 0;
        });

        final newPKState = data['pkState'] as Map<String, dynamic>? ?? {'isPK': false};
        final bool isNowInPK = newPKState['isPK'] == true;

        // PK Just Started
        if (isNowInPK && !_isPKMode) {
          if (!_isStartingPKAnimation) {
            _startPKBattleSequence(newPKState);
          }
        }
        // PK Just Ended
        else if (!isNowInPK && _isPKMode) {
          debugPrint("PK Mode ENDING");
          if (widget.isHost) {
            String opponentHostId = _pkState['opponentHostId'] ?? '';
            if (opponentHostId.isNotEmpty) {
              ZegoUIKit().stopPlayAnotherRoomAudioVideo(opponentHostId);
            }
          }
          _opponentParticipantsSubscription?.cancel();

          _pkTimer?.cancel();

          setState(() {
            _isPKMode = false;
            _pkState = {};
            _opponentParticipants = [];
            _pkTimerDisplay = "00:00";
          });
        }
      } else {
        if (mounted) context.pop();
      }
    });

    _messageSubscription = ZegoUIKit().getInRoomMessageStream().listen((message) {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              userId: message.user.id,
              username: message.user.name,
              message: message.message,
              timestamp: DateTime.now(),
            ),
          );
          _scrollToNewestMessage();
        });
      }
    });

    _participantsSubscription = VideoRoomService.getRoomParticipants(widget.roomID).listen((snapshot) {
      if (mounted) {
        // This is the full list from Firestore
        final newParticipants = snapshot.docs.map((doc) => VideoParticipant.fromFirestore(doc)).toList();
        final currentUser = _auth.currentUser!;

        // --- Welcome Animation Logic ---
        if (_allParticipants.isNotEmpty && _newJoinerName == null) {
          final oldParticipantIds = _allParticipants.map((p) => p.userId).toSet();
          final String hostId = roomData['hostId'] ?? '';

          final newGuest = newParticipants.firstWhere(
            (p) => !oldParticipantIds.contains(p.userId) && p.userId != hostId,
            orElse: () => VideoParticipant(userId: '', userName: '', isMuted: true, isCameraOn: false, onCall: false),
          );

          if (newGuest.userId.isNotEmpty) {
            _showJoinAnimation(newGuest.userName);
          }
        }
        // --- End Welcome Animation Logic ---

        final currentUserParticipant = newParticipants.firstWhereOrNull((p) => p.userId == currentUser.uid);
        final bool isNowOnCall = currentUserParticipant?.onCall ?? false;

        if (isNowOnCall && !_isJoined) {
          debugPrint("Join request approved! Starting local video/audio stream.");
          ZegoUIKit().turnMicrophoneOn(true);
          ZegoUIKit().turnCameraOn(true);
        } else if (!isNowOnCall && _isJoined) {
          debugPrint("Removed from call. Stopping local video/audio stream.");
          ZegoUIKit().turnMicrophoneOn(false);
          ZegoUIKit().turnCameraOn(false);
        }

        setState(() {
          _participants = newParticipants.where((p) => p.onCall == true).toList();
          _allParticipants = newParticipants; // <-- STORE THE FULL LIST
          _isJoined = isNowOnCall;
        });
      }
    });

    if (widget.isHost) {
      _joinRequestsSubscription = VideoRoomService.getJoinRequestsStream(widget.roomID).listen((snapshot) {
        if (mounted) {
          setState(() => _joinRequests = snapshot.docs.map((doc) => JoinRequest.fromFirestore(doc)).toList());
        }
      });

      _pkInvitesSubscription = VideoRoomService.getPKInvitesStream(widget.roomID).listen((invites) {
        print('Received PK invites: $invites');
        setState(() {
          _pendingInvites = invites;
        });

        final newInvite = invites.firstWhereOrNull((invite) => !_dialogsShownForInviteIds.contains(invite.id));

        if (newInvite != null) {
          _dialogsShownForInviteIds.add(newInvite.id);
          _showPKInviteDialog(newInvite);
        }
      });

      _sentPKInvitesSubscription = VideoRoomService.getSentPKInvitesStream(widget.roomID).listen((acceptedInvites) {
        print('Received accepted PK invites: $acceptedInvites');

        final newAcceptedInvite = acceptedInvites.firstWhereOrNull(
          (invite) => !_dialogsShownForInviteIds.contains(invite.id),
        );

        if (newAcceptedInvite != null && !_isPKMode) {
          _dialogsShownForInviteIds.add(newAcceptedInvite.id);
        }
      });
    }
  }

  void _startPKTimer(DateTime endTime) {
    _pkTimer?.cancel();
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _pkTimerDisplay = "00:00";
        });
        if (widget.isHost && _isPKMode) {
          debugPrint("PK Timer finished. Ending battle.");
          VideoRoomService.endPKBattle(widget.roomID, _pkState['opponentRoomId']);
        }
      } else {
        setState(() {
          _pkTimerDisplay = _formatDuration(remaining);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // --- Welcome Animation Method ---
  void _showJoinAnimation(String userName) {
    _joinAnimationTimer?.cancel();

    _joinAnimationController.forward(from: 0.0);

    setState(() {
      _newJoinerName = userName;
    });

    _joinAnimationTimer = Timer(welcomeTime, () {
      setState(() {
        _newJoinerName = null;
      });
    });
  }

  // --- End Welcome Animation Method ---

  Future<void> _showPKInviteDialog(PKInvite invite) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'PK Invitation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          // USE AutoScrollText for long host names in dialog
          '${invite.senderHostName} wants to start a ${invite.durationInMinutes}-minute PK. What do you want to do?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              VideoRoomService.rejectPKInvite(widget.roomID, invite);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Just close dialog
            child: const Text('Later', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();

              // Force camera on
              ZegoUIKit().turnCameraOn(true);
              VideoRoomService.toggleCameraState(widget.roomID, true);

              VideoRoomService.acceptPKInvite(widget.roomID, invite);
              ZegoUIKit().startPlayAnotherRoomAudioVideo(invite.senderRoomId, invite.senderHostId);
              // Re-apply view mode for the new remote stream
              ZegoUIKit().updateVideoViewMode(true);
            },
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        backgroundColor: Colors.black,
        body: Builder(
          builder: (builderContext) {
            ZegoScreenUtil.init(builderContext);

            if (!_isInitialized) {
              return _buildLoadingIndicator();
            }

            return Stack(
              children: [
                _isPKMode ? _buildPKModeLayout() : _buildStandardModeLayout(),
                Visibility(visible: _isStartingPKAnimation, child: _buildPKStartingAnimation()),

                // --- Add Welcome Animation Overlay ---
                Center(child: _buildJoinAnimationOverlay()),
                // --- End Welcome Animation Overlay ---
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatContainer({required Widget chatListWidget}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 1.0],
          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Column(
        children: [
          chatListWidget,
          SafeArea(top: false, child: _buildChatInput()),
        ],
      ),
    );
  }

  Widget _buildStandardModeLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildStandardVideoLayout()),
        if (_isInitialized)
          Column(
            children: [
              _buildAppBar(),
              _buildHostStatsRow(),
              Spacer(),
              _buildChatContainer(
                chatListWidget: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  child: Stack(children: [_buildChatSection(), _buildJoinCallOverlay()]),
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildPKModeLayout() {
    return Column(
      children: [
        _buildAppBar(),
        _buildHostStatsRow(),
        Expanded(flex: 2, child: _buildPKVideoLayout()),
        _buildPKProgressBar(),
        _buildPKEmptySeats(),
        Expanded(
          flex: 2,
          child: _buildChatContainer(chatListWidget: Expanded(flex: 1, child: _buildChatSection())),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b)],
        ),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );
  }

  Widget _buildHostStatsRow() {
    final String hostId = roomData['hostId'] ?? '';
    if (hostId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: ProfileService.getUserProfileStream(hostId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;

        final int starCount = data['starCount'] ?? 0;
        final int diamondCount = data['diamondCount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
          child: Row(
            children: [
              _buildStatChip(Icons.star_rounded, starCount.toString(), Colors.yellow.shade700),
              const SizedBox(width: 8),
              _buildStatChip(Icons.diamond_rounded, diamondCount.toString(), Colors.cyan.shade300),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPKScoreChip(String score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          score,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPKProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 12,
              color: Colors.black45,
              child: Row(
                children: [
                  // TODO: Wire up flex to score percentage
                  Expanded(flex: 1, child: Container(color: Colors.blue)),
                  Expanded(flex: 1, child: Container(color: Colors.red)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPKScoreChip(_pkScoreBlue.toString(), Colors.blue.shade300),
                _buildPKScoreChip(_pkScoreRed.toString(), Colors.red.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPKTimerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Text(
        _pkTimerDisplay,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildPKEmptySeats() {
    Widget buildSeatIcon(int number) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.event_seat_rounded, color: Colors.amber, size: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            number.toString(),
            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) => buildSeatIcon(index + 1)),
          ),
          const Spacer(),
          _buildPKTimerWidget(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) => buildSeatIcon(index + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final String hostId = roomData['hostId'] ?? '';
    final String currentUserId = _auth.currentUser?.uid ?? '';
    final bool isGuest = !widget.isHost && hostId != currentUserId;

    List<VideoParticipant> participantsForAvatars = [];
    if (!_isPKMode) {
      // Use _allParticipants for the avatar stack
      participantsForAvatars = _allParticipants.where((p) => p.userId != hostId).toList();
    }

    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Open the profile bottom sheet for the host
                  showProfileInfoBottomSheet(context, userId: hostId, hostId: hostId, roomId: widget.roomID);
                },
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundImage: NetworkImage(roomData['hostPicture'] ?? '')),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_isPKMode)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Text(
                                  'PK',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            // REPLACED Text with AutoScrollText
                            SizedBox(
                              width: 120, // Constrain width for scrolling
                              child: AutoScrollText(
                                text: roomData["hostName"],
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ID: ${hostId.length > 8 ? hostId.substring(hostId.length - 8) : hostId}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isGuest)
                StreamBuilder<bool>(
                  stream: ProfileService.isFollowing(hostId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final bool isFollowing = snapshot.data ?? false;

                    if (isFollowing) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await ProfileService.followUser(hostId);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.pink.shade400, width: 1.5),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(4),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Icon(Icons.add, color: Colors.pink.shade300, size: 20),
                      ),
                    );
                  },
                ),
              const Spacer(),
              // Show avatars and count button ONLY if NOT in PK mode
              if (!_isPKMode) ...[
                _buildParticipantAvatars(participantsForAvatars),
                GestureDetector(
                  onTap: () {
                    showVideoParticipantsBottomSheet(
                      context,
                      // Pass the full list to the participants bottom sheet
                      participants: _allParticipants,
                      currentUserId: _auth.currentUser!.uid,
                      roomId: widget.roomID,
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
              ],
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

  Widget _buildParticipantAvatars(List<VideoParticipant> participants) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    const double avatarSize = 20.0;
    const double overlap = 15.0;

    final participantsToShow = participants.take(5).toList();

    final double stackWidth = avatarSize + (participantsToShow.length - 1) * overlap;

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(
        children: participantsToShow
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final participant = entry.value;
              final double leftPosition = index * overlap;

              return Positioned(
                left: leftPosition,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: (avatarSize / 2) - 1,
                    backgroundImage: participant.userPicture != null && participant.userPicture!.isNotEmpty
                        ? NetworkImage(participant.userPicture!)
                        : null,
                    child: (participant.userPicture == null || participant.userPicture!.isEmpty)
                        ? const Icon(Icons.person, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
              );
            })
            .toList()
            .reversed
            .toList(),
      ),
    );
  }

  Widget _buildPKVideoLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildTeamLayout(
                  participants: _participants,
                  hostName: roomData['hostName'] ?? 'Host A',
                  isPKTeam: true,
                ), // Pass PK status
              ),
              Expanded(
                child: _buildTeamLayout(
                  participants: _opponentParticipants,
                  hostName: _pkState['opponentHostName'] ?? 'Host B',
                  isPKTeam: true, // Pass PK status
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardVideoLayout() {
    return _buildTeamLayout(
      participants: _participants,
      hostName: roomData['hostName'] ?? 'Host',
      isHost: widget.isHost,
    );
  }

  Widget _buildTeamLayout({
    required List<VideoParticipant> participants,
    required String hostName,
    bool isHost = false,
    bool isPKTeam = false,
  }) {
    if (participants.isEmpty) {
      if (isHost) {
        final zegoUser = ZegoUIKit().getUser(_auth.currentUser!.uid);
        if (zegoUser != null) {
          return buildZegoView(
            VideoParticipant(
              userId: zegoUser.id,
              userName: zegoUser.name,
              isMuted: !zegoUser.microphone.value,
              isCameraOn: zegoUser.camera.value,
              onCall: true,
            ),
          );
        }
      }
      return Center(
        child: Text('Waiting for $hostName...', style: const TextStyle(color: Colors.white)),
      );
    }

    switch (participants.length) {
      case 1:
        return buildZegoView(participants[0]);
      case 2:
        return Column(
          children: [
            Expanded(child: buildZegoView(participants[0])),
            Expanded(child: buildZegoView(participants[1])),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(flex: 2, child: buildZegoView(participants[0])),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: buildZegoView(participants[1])),
                  Expanded(child: buildZegoView(participants[2])),
                ],
              ),
            ),
          ],
        );
      case 4:
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            return buildZegoView(participants[index]);
          },
        );
      default:
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.0),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            return buildZegoView(participants[index]);
          },
        );
    }
  }

  Widget buildZegoView(VideoParticipant participant) {
    if (participant.isCameraOn) {
      final zegoUser = ZegoUIKit().getUser(participant.userId);
      if (zegoUser != null) {
        return SizedBox.expand(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: ValueListenableBuilder<Size>(
                valueListenable: ZegoUIKit().getVideoSizeNotifier(participant.userId),
                builder: (context, videoSize, _) {
                  return SizedBox(
                    width: videoSize.width,
                    height: videoSize.height,
                    child: ZegoAudioVideoView(user: zegoUser),
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    // Fallback for when the camera is off (avatar view)
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
    return ListView.builder(
      reverse: true,
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
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
              GestureDetector(
                onTap: () {
                  showProfileInfoBottomSheet(
                    context,
                    userId: m.userId,
                    hostId: roomData['hostId'] ?? '',
                    roomId: widget.roomID,
                  );
                },
                child: Row(
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
                    // Only the message text should NOT be autoscroll text,
                    // but the username here should be to prevent overflow in chat bubbles.
                    SizedBox(
                      width: 120, // Constrain width for scrolling
                      child: Text(
                        "${m.username}: ",
                        style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0, top: 2),
                child: Text(m.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        );
      },
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
    final bool isPKHost = widget.isHost && _isPKMode;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                showToolsBottomSheet(
                  context,
                  pendingInvites: _pendingInvites,
                  currentRoomId: widget.roomID,
                  isHost: widget.isHost,
                  hostName: roomData['hostName'] ?? 'Host',
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gift button tapped!')));
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 22),
              ),
            ),
          ),
          if (widget.isHost && !_isPKMode)
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                      child: const Icon(CupertinoIcons.person_add_solid, color: Colors.white, size: 22),
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
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 22),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: Icon(
                    isCurrentlyMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                    color: isCurrentlyMuted ? Colors.white : Colors.pink,
                    size: 22,
                  ),
                ),
              ),
            ),
            if (!isPKHost)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    final newCameraState = !isCameraOn;
                    VideoRoomService.toggleCameraState(widget.roomID, newCameraState);
                    ZegoUIKit().turnCameraOn(newCameraState);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                    child: Icon(
                      isCameraOn ? CupertinoIcons.videocam_fill : Icons.videocam_off,
                      color: isCameraOn ? Colors.pink : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ] else
            const SizedBox.shrink(),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _sendJoinMessage() async {
    const messageText = "Just joined the room!";
    try {
      await ZegoUIKit().sendInRoomMessage(messageText);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              userId: _auth.currentUser!.uid,
              username: _currentUserName,
              message: messageText,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error sending join message: $e');
    }
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
            userId: _auth.currentUser?.uid ?? '',
            username: _currentUserName,
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

  Widget _buildJoinAnimationOverlay() {
    return Visibility(
      visible: _newJoinerName != null,
      child: Container(
        width: double.infinity,
        height: 100,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        child: SlideTransition(
          position: _joinAnimationOffset,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Image.asset("assets/animations/id_entry.gif", fit: BoxFit.cover),
              Center(
                child: Text(
                  '${_newJoinerName ?? ''} joined!',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    shadows: [BoxShadow(color: Colors.black54, blurRadius: 4, spreadRadius: 2)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPKStartingAnimation() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * .2),
              height: MediaQuery.of(context).size.height / 2,
              child: Image.asset("assets/animations/pk_start.gif", fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }
}
