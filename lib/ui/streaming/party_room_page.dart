// lib/ui/streaming/party_room_page.dart
// Party Room — keeps the party grid UI, wired with real REST + Zego logic.

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:flutter/cupertino.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../data/remote/rest/models/room_response_model.dart';
import '../../data/remote/rest/room_api_service.dart';
import '../../navigation/routes.dart';
import 'bottomsheets/play_music_bottomsheet.dart';
import 'bottomsheets/audio_tools_bottomsheet.dart';
import 'bottomsheets/emoji_bottomsheet.dart';
import 'bottomsheets/gifts_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';
import '../../data/remote/socket/socket_service.dart';

// ──────────────────────────── DATA MODELS ────────────────────────────

class _PartySlot {
  final bool isOccupied;
  final String username;
  final String? photoUrl;
  final bool micOn;
  final bool isHost;
  final int giftCount;
  final Color avatarColor;
  final String? userId;
  final int? seatNo;
  final bool isMuted;
  final ZegoUIKitUser? zegoUser;

  _PartySlot({
    required this.isOccupied,
    this.username = '',
    this.photoUrl,
    this.micOn = true,
    this.isHost = false,
    this.giftCount = 0,
    this.avatarColor = const Color(0xFF5B5B7A),
    this.userId,
    this.seatNo,
    this.isMuted = false,
    this.zegoUser,
  });
}

class _ChatMsg {
  final String sender;
  final String text;
  final bool isSystem;

  _ChatMsg({required this.sender, required this.text, this.isSystem = false});
}

// ──────────────────────────── WIDGET ────────────────────────────

class PartyRoomPage extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final int slotCount;
  final String mode;
  final ZegoConfig? zegoConfig;

  const PartyRoomPage({
    super.key,
    required this.roomId,
    required this.isHost,
    this.slotCount = 9,
    this.mode = 'voice',
    this.zegoConfig,
  });

  @override
  State<PartyRoomPage> createState() => _PartyRoomPageState();
}

class _PartyRoomPageState extends State<PartyRoomPage>
    with TickerProviderStateMixin {
  // ── Zego credentials (hardcoded — no parsing that can fail)
  static const int _zegoAppId = 423730354;
  static const String _zegoAppSign =
      'cec0bbcfd59fcadabe5511c354ffe19d6fe71a470ad75f177d2712bf25b3734b';

  // ── Services
  final _roomApi = GetIt.instance<RoomApiService>();
  final _secureStorage = GetIt.I<SecureStorage>();
  final _socketService = GetIt.I<SocketService>();
  late MusicPlayerManager _musicPlayerManager;

  // ── Room state
  RoomModel? _roomModel;
  Map<String, dynamic> _roomData = {};
  List<RoomParticipant_> _participants = [];
  bool _isInitialized = false;
  bool _roomDoesNotExist = false;
  String _currentUserId = '';
  String _currentUserName = 'Me';
  int _participantCount = 0;
  bool _isSeatApprovalRequired = false;
  bool _isMoveAllowed = true;
  bool _isMicOn = false; // starts false; set correctly after init
  List<dynamic> _coHostRequests = [];
  List<dynamic> _speakerRequests = [];

  // ── Timers / subscriptions
  Timer? _pollTimer;
  StreamSubscription? _msgSub;
  StreamSubscription? _userJoinSub;
  StreamSubscription? _userLeaveSub;
  StreamSubscription? _socketParticipantSub;
  StreamSubscription? _socketCommentSub;

  // ── Chat
  int _chatTab = 0;
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  final List<_ChatMsg> _messages = [];

  // ── Quick-reply chips
  final List<String> _quickReplies = ['Hi there!', 'Welcome 🎉', 'Plz Follow👋'];
  int _selectedQuickReply = 0;

  // ────────────────────── LIFECYCLE ──────────────────────

  @override
  void initState() {
    super.initState();
    _musicPlayerManager = MusicPlayerManager();
    _initialize(); // ← entry point
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgSub?.cancel();
    _userJoinSub?.cancel();
    _userLeaveSub?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    _musicPlayerManager.dispose();
    _socketParticipantSub?.cancel();
    _socketCommentSub?.cancel();
    _socketService.disconnect();

    if (_isInitialized) {
      // 1. Mute mic (hardware off), stop receiving others' audio
      ZegoUIKit().turnMicrophoneOn(false);       // hardware OFF — stops publishing
      ZegoUIKit().stopPlayAllAudioVideo();        // stop receiving

      // 2. Notify backend
      if (widget.isHost) {
        _roomApi.deleteRoom(widget.roomId);
      } else {
        _roomApi.leaveRoom(widget.roomId);
      }

      // 3. Leave Zego room, then logout, then uninit (must be in this order)
      ZegoUIKit().leaveRoom().then((_) {
        ZegoUIKit().logout();
        ZegoUIKit().uninit();
      });
    }
    super.dispose();
  }

  // ────────────────────── STEP 0 — fetch room info ──────────────────────
  // This is the real entry point called from initState.
  // It fetches room data, checks password if locked, then calls _finishInit().

  Future<void> _initialize() async {
    try {
      final response = await _roomApi.getRoomInfo(widget.roomId);

      if (response == null || !response.status) {
        if (mounted) setState(() => _roomDoesNotExist = true);
        return;
      }

      _roomModel = response.data.room;
      final room = _roomModel!;

      _roomData = {
        'roomId': room.roomId,
        'hostId': room.hostId,
        'hostName': room.hostName,
        'hostPicture': room.hostPicture,
        'backgroundUrl': room.backgroundUrl,
        'isLocked': room.isLocked,
        'password': room.password,
        'isMoveAllowed': room.isMoveAllowed,
        'isSeatApprovalRequired': room.isSeatApprovalRequired,
      };

      // Password gate for guests
      if (room.isLocked && !widget.isHost) {
        final ok = await _showPasswordDialog();
        if (ok != true) {
          if (mounted && context.canPop()) context.pop();
          return;
        }
      }

      await _finishInit();
    } catch (e) {
      debugPrint('❌ [PARTY_ROOM] _initialize error: $e');
      if (mounted) context.go(Routes.home.path);
    }
  }

  // ────────────────────── STEP 1–6 — Zego init ──────────────────────

  Future<void> _finishInit() async {
    // ── Microphone permission
    if (!await _checkMicPermission()) {
      if (mounted) context.pop();
      return;
    }

    // ── Get current user from secure storage
    final user = await _secureStorage.getUser();
    if (user == null) {
      if (mounted) context.go(Routes.login.path);
      return;
    }
    _currentUserId = user.id;
    _currentUserName = user.name;

    // ──────────────────────────────────────────────────────────────
    // STEP 1 — init SDK (async — must fully complete first)
    // ──────────────────────────────────────────────────────────────
    print('🚀 [ZEGO] Step 1: init appId=$_zegoAppId');
    await ZegoUIKit().init(
      appID: _zegoAppId,
      appSign: _zegoAppSign,
      scenario: ZegoScenario.Default,
    );
    print('✅ [ZEGO] Init complete');

    // ──────────────────────────────────────────────────────────────
    // STEP 2 — login user (VOID — no await, do NOT await this)
    // SDK source: `void login(String id, String name)`
    // ──────────────────────────────────────────────────────────────
    print('🚀 [ZEGO] Step 2: login userId=$_currentUserId name=$_currentUserName');
    ZegoUIKit().login(_currentUserId, _currentUserName); // ← NO await
    print('✅ [ZEGO] Login called');

    // ──────────────────────────────────────────────────────────────
    // STEP 3 — join REST room (guests only) to get Zego token + roomId
    // ──────────────────────────────────────────────────────────────
    String zegoRoomId = widget.roomId;
    String token = '';

    if (!widget.isHost) {
      print('🚀 [ZEGO] Step 3a: REST joinRoom for roomId=${widget.roomId}');
      final joinRes = await _roomApi.joinRoom(widget.roomId);

      if (joinRes != null && joinRes.status) {
        zegoRoomId = joinRes.data.zegoConfig.roomId ?? widget.roomId;
        token = joinRes.data.zegoConfig.token ?? '';
        setState(() {
          _participants = joinRes.data.participants
              .map((p) => RoomParticipant_.fromJoin(p))
              .toList();
          _participantCount = joinRes.data.room.participantCount;
          _isMoveAllowed = joinRes.data.room.isMoveAllowed;
          _isSeatApprovalRequired = joinRes.data.room.isSeatApprovalRequired;
        });
        print('✅ [ZEGO] REST join OK — zegoRoomId=$zegoRoomId token=${token.isEmpty ? "(empty)" : "provided"}');
      } else {
        print('❌ [ZEGO] REST join failed: ${joinRes?.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to join: ${joinRes?.message ?? "Error"}'),
          ));
          context.pop();
        }
        return;
      }
    } else {
      // Host: token comes from createRoom response via widget.zegoConfig
      token = widget.zegoConfig?.token ?? _roomModel?.zegoConfig?.token ?? '';
      zegoRoomId = widget.zegoConfig?.roomId ?? widget.roomId;
      print('✅ [ZEGO] Host path — zegoRoomId=$zegoRoomId token=${token.isEmpty ? "(empty=AppSign mode)" : "provided"}');
    }

    // ──────────────────────────────────────────────────────────────
    // STEP 4 — join Zego room
    // token can be empty string when using AppSign auth (dev mode)
    // ──────────────────────────────────────────────────────────────
    print('🚀 [ZEGO] Step 4: joinRoom zegoRoomId=$zegoRoomId');
    await ZegoUIKit().joinRoom(zegoRoomId, token: token);
    print('✅ [ZEGO] Joined Zego room');

    // ──────────────────────────────────────────────────────────────
    // STEP 5 — configure audio (MUST be after joinRoom)
    // Small delay ensures the room is fully ready server-side.
    // ──────────────────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 500));

    // Route audio to speaker so everyone can hear
    ZegoUIKit().setAudioOutputToSpeaker(true);

    // ── How turnMicrophoneOn works (from SDK source):
    //
    //   turnMicrophoneOn(isOn, muteMode: false)  → physically turns device ON/OFF
    //                                              (publishing starts when isOn=true)
    //   turnMicrophoneOn(isOn, muteMode: true)   → keeps device on, just mutes/unmutes
    //                                              the published stream (stays in room)
    //
    // For audio rooms: ALWAYS use muteMode:true after the first turnOn(true).
    // This way the stream stays published and muting/unmuting works instantly.
    //
    // Correct sequence:
    //   1. turnMicrophoneOn(true)             → starts publishing + opens mic hardware
    //   2. if guest: turnMicrophoneOn(false, muteMode:true) → mutes stream, keeps publishing
    //   3. on mic button tap: turnMicrophoneOn(newState, muteMode:true) → instant toggle

    // Step 5a: Turn mic ON for everyone — this starts the publish stream
    ZegoUIKit().turnMicrophoneOn(true);
    await Future.delayed(const Duration(milliseconds: 200)); // let publish establish

    // Step 5b: Guests start muted (stream published but silenced)
    if (!widget.isHost) {
      ZegoUIKit().turnMicrophoneOn(false, muteMode: true);
    }

    // Step 5c: Start receiving all other users' audio
    await ZegoUIKit().startPlayAllAudioVideo();

    setState(() => _isMicOn = widget.isHost);
    print('✅ [ZEGO] Audio ready — host=${widget.isHost} micOn=$_isMicOn speaker=true');

    // ──────────────────────────────────────────────────────────────
    // STEP 6 — subscribe to streams
    // ──────────────────────────────────────────────────────────────

    // Chat messages
    _msgSub = ZegoUIKit().getInRoomMessageStream().listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMsg(sender: msg.user.name, text: msg.message));
        });
        _scrollToBottom();
      }
    });

    // User join/leave — refresh seat grid immediately
    _userJoinSub = ZegoUIKit().getUserJoinStream().listen((users) {
      for (final u in users) {
        print('👤 [ZEGO] Joined: ${u.name} (${u.id})');
      }
      if (mounted) _poll();
    });

    _userLeaveSub = ZegoUIKit().getUserLeaveStream().listen((users) {
      for (final u in users) {
        print('👤 [ZEGO] Left: ${u.name} (${u.id})');
      }
      if (mounted) _poll();
    });

    // ── Mark as ready and start polling
    setState(() => _isInitialized = true);
    _musicPlayerManager.initialize();

    await _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _poll();
    });

    // ── Socket initialization
    final jwtToken = await _secureStorage.getToken();
    if (jwtToken != null) {
      _socketService.connect(jwtToken, widget.roomId);
      
      _socketParticipantSub = _socketService.participantJoinedStream.listen((data) {
        debugPrint('👥 [PARTY_ROOM] Socket: participant_joined');
        if (mounted) _poll(); // Refresh list on join
      });

      _socketCommentSub = _socketService.newCommentStream.listen((data) {
        debugPrint('💬 [PARTY_ROOM] Socket: new_comment $data');
        if (mounted) {
          setState(() {
            _messages.add(_ChatMsg(
              sender: data['userName'] ?? 'User',
              text: data['text'] ?? '',
            ));
          });
          _scrollToBottom();
        }
      });
    }

    print('✅ [ZEGO] Room fully initialized');
  }

  // ────────────────────── POLLING ──────────────────────

  Future<void> _poll() async {
    try {
      final res = await _roomApi.getRoomInfo(widget.roomId);
      if (res != null && res.status && mounted) {
        final room = res.data.room;
        setState(() {
          _roomModel = room; // Update room model to refresh seats
          _participants = room.participants
              .map((p) => RoomParticipant_.fromParticipant(p))
              .toList();
          _participantCount = room.participantCount;
          _isMoveAllowed = room.isMoveAllowed;
          _isSeatApprovalRequired = room.isSeatApprovalRequired;
        });
      }
    } catch (e) {
      debugPrint('PartyRoomPage poll error: $e');
    }
  }

  // ────────────────────── BUILD SLOTS FROM PARTICIPANTS ──────────────────────

  List<_PartySlot> _buildSlotList() {
    final int count = ((_roomModel?.maxSeats ?? 0) > 0)
        ? _roomModel!.maxSeats
        : (widget.slotCount > 0 ? widget.slotCount : 18);

    final slots = List<_PartySlot>.generate(
      count,
      (_) => _PartySlot(isOccupied: false),
    );

    // Source of truth: use 'seats' array from API
    if (_roomModel != null && _roomModel!.seats.isNotEmpty) {
      for (var seat in _roomModel!.seats) {
        if (seat.seatNo >= 0 && seat.seatNo < count) {
          if (seat.isOccupied && seat.user != null) {
            // Find matched participant to get zegoUser (for audio levels)
            final p = _participants.cast<RoomParticipant_?>().firstWhere(
                  (part) => part?.userId == seat.user!.id,
              orElse: () => null,
            );

            slots[seat.seatNo] = _PartySlot(
              isOccupied: true,
              userId: seat.user!.id,
              username: seat.user!.name,
              photoUrl: seat.user!.photoUrl,
              seatNo: seat.seatNo,
              isMuted: seat.isMuted,
              micOn: !seat.isMuted,
              isHost: seat.seatNo == 0,
              zegoUser: p?.zegoUser, // Matching Zego Info
              avatarColor: seat.seatNo == 0 ? const Color(0xFF7B5EA7) : const Color(0xFF5B8EA7),
            );
          }
        }
      }
    } else {
      // Fallback to _roomData if no seats yet (Initial state)
      slots[0] = _PartySlot(
        isOccupied: true,
        isHost: true,
        username: _roomData['hostName'] ?? 'Host',
        photoUrl: _roomData['hostPicture'],
        micOn: true,
        userId: _roomData['hostId'],
        seatNo: 0,
      );
    }

    return slots;
  }

  // ────────────────────── HELPERS ──────────────────────

  // ────────────────────── MIC CONTROL ──────────────────────
  // From SDK source: turnMicrophoneOn(isOn, muteMode: false) = hardware ON/OFF
  //                  turnMicrophoneOn(isOn, muteMode: true)  = mute/unmute only
  //
  // After the initial turnMicrophoneOn(true) in _finishInit, the publish stream
  // is active. All subsequent toggles MUST use muteMode:true so the stream
  // stays published and audio resumes instantly without re-establishing connection.
  void _setMic(bool isOn) {
    ZegoUIKit().turnMicrophoneOn(isOn, muteMode: true);
  }

  Future<bool> _checkMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool?> _showPasswordDialog() async {
    final ctrl = TextEditingController();
    final completer = Completer<bool?>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        String? err;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            backgroundColor: const Color(0xFF2d1b2b),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Password Required', style: TextStyle(color: Colors.white)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('This room is locked.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: err,
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
            ]),
            actions: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  Navigator.of(dCtx).pop();
                  completer.complete(false);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Enter', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (ctrl.text == _roomData['password']) {
                    Navigator.of(dCtx).pop();
                    completer.complete(true);
                  } else {
                    setSt(() => err = 'Incorrect password');
                    ctrl.clear();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    return completer.future;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Do you want to exit the room?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(
            _chatScrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    
    // Send via Socket.io
    _socketService.sendComment(text);
    
    // Also send via Zego for fallback/compatibility if needed, 
    // but the socket should handle the broadcast now.
    ZegoUIKit().sendInRoomMessage(text);
    
    setState(() {
      _messages.add(_ChatMsg(sender: _currentUserName, text: text));
    });
    _chatController.clear();
    _scrollToBottom();
  }

  Future<void> _takeSeat(int seatNo) async {
    final res = await _roomApi.takeSeat(widget.roomId, seatNo);
    if (res != null && res.status) {
      // Stream is already published from _finishInit.
      // Just unmute using muteMode:true — instant, no reconnection needed.
      _setMic(true);
      setState(() => _isMicOn = true);
      // Tell backend mic is now unmuted
      _roomApi.updateMuteState(widget.roomId, false);
      await _poll();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take seat: ${res?.message ?? "Error"}')),
      );
    }
  }

  Future<void> _moveSeat(int newSeatNo) async {
    final res = await _roomApi.moveSeat(widget.roomId, newSeatNo);
    if (res != null && res.status) {
      await _poll();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move seat: ${res?.message ?? "Error"}')),
      );
    }
  }

  // ────────────────────── UI ──────────────────────

  int _gridCols(int count) {
    if (count <= 4) return 2;
    if (count <= 6) return 3;
    if (count <= 9) return 3;
    if (count <= 16) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    if (_roomDoesNotExist) return _buildRoomEndedScreen();

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        if (shouldExit == true && mounted) {
          if (context.canPop()) context.pop();
        }
        return false; // always return false; we handle navigation manually
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0820),
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: _isInitialized
                  ? _buildBody()
                  : const Center(
                  child: CircularProgressIndicator(color: Colors.pink)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomEndedScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_off_rounded, size: 60, color: Colors.white70),
              const SizedBox(height: 20),
              const Text('Room Ended',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'This room has ended or does not exist.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(Routes.home.path),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25))),
                child: const Text('Go Home', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final url = _roomData['backgroundUrl'] as String?;
    if (url != null && url.isNotEmpty) {
      return Positioned.fill(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.45),
          colorBlendMode: BlendMode.darken,
          placeholder: (_, __) => Container(color: const Color(0xFF1A0820)),
          errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A0820)),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0D3E), Color(0xFF1E1050), Color(0xFF0D0820)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBody() {
    final slots = _buildSlotList();
    final int cols = _gridCols(slots.length);
    final double screenW = MediaQuery.of(context).size.width;
    final double slotSize = (screenW - 2) / cols;

    return Column(
      children: [
        _buildTopBar(),
        _buildStatsBar(slots),
        _buildWishRow(),
        _buildSlotGrid(slots, cols, slotSize),
        Expanded(child: _buildChatSection()),
        _buildBottomBar(),
      ],
    );
  }

  // ─── TOP BAR ───

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          _buildAvatarBubble(
            url: _roomData['hostPicture'] as String?,
            initial: (_roomData['hostName'] as String? ?? '').isNotEmpty
                ? (_roomData['hostName'] as String).substring(0, 1).toUpperCase()
                : 'H',
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                SizedBox(width: 3),
                Text('0',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '$_participantCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.person, color: Colors.white70, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final exit = await _showExitDialog();
              if (exit == true && mounted) {
                if (context.canPop()) context.pop();
              }
            },
            child: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBubble(
      {String? url, required String initial, double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initials(initial, size),
        )
            : _initials(initial, size),
      ),
    );
  }

  Widget _initials(String text, double size) {
    return Container(
      color: const Color(0xFF7B5EA7),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── STATS BAR ───

  Widget _buildStatsBar(List<_PartySlot> slots) {
    final roomId = _roomData['roomId'] as String? ?? widget.roomId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 4),
          Text(
            _roomData['hostName'] as String? ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            'ID: ${roomId.length > 8 ? roomId.substring(0, 8) : roomId}',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(width: 8),
          Text(
            'Seats: ${slots.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── WISH ROW ───

  Widget _buildWishRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
          const SizedBox(width: 4),
          const Text('Wish', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Invite friends\nUp to 🎁10k',
              style: TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SLOT GRID ───

  Widget _buildSlotGrid(List<_PartySlot> slots, int cols, double slotSize) {
    final myParticipant = _participants.firstWhere(
          (p) => p.userId == _currentUserId,
      orElse: () => RoomParticipant_(
          userId: '', userName: '', seatNo: -1, isCoHost: false, isMuted: true),
    );
    final bool meOnSeat = _roomModel?.seats.any(
          (s) => s.isOccupied && s.user?.id == _currentUserId,
    ) ?? false;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 1.0,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _buildSlotCell(slot, index, slotSize, meOnSeat);
      },
    );
  }

  Widget _buildSlotCell(_PartySlot slot, int index, double size, bool meOnSeat) {
    return GestureDetector(
      onTap: () async {
        if (slot.isOccupied) return;
        if (widget.isHost) return;

        final int targetSeat = slot.seatNo ?? index;

        // ── Source of truth: check seats array from API, NOT _participants
        // _participants.seatNo can be stale; seats array is always fresh from _poll()
        final bool meOnSeat = _roomModel?.seats.any(
              (s) => s.isOccupied && s.user?.id == _currentUserId,
        ) ?? false;

        debugPrint('🪑 [SEAT_TAP] index=$index targetSeat=$targetSeat meOnSeat=$meOnSeat approval=$_isSeatApprovalRequired');

        if (meOnSeat) {
          if (!_isMoveAllowed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seat movement is not allowed in this room')),
            );
            return;
          }
          await _moveSeat(targetSeat);
          return;
        }

        // Not seated → take seat
        if (_isSeatApprovalRequired) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat requires approval')),
          );
          return;
        }

        await _takeSeat(targetSeat);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
          color: Colors.black.withOpacity(0.12),
        ),
        child: slot.isOccupied
            ? _buildOccupiedSlot(slot, index, size)
            : _buildEmptySlot(index),
      ),
    );
  }

  Widget _buildOccupiedSlot(_PartySlot slot, int index, double size) {
    return Stack(
      children: [
        Container(color: slot.avatarColor.withOpacity(0.2)),
        Positioned.fill(
          child: Center(
            child: _buildSlotAvatar(slot, size),
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Text('${index + 1}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                slot.micOn ? Icons.mic : Icons.mic_off,
                color: slot.micOn ? Colors.white : Colors.red,
                size: 10,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  slot.username,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (slot.isHost)
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('HOST',
                  style: TextStyle(
                      color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildSlotAvatar(_PartySlot slot, double slotSize) {
    final double avatarSize = slotSize * 0.44; // diameter 
    final String initial = (slot.username != null && slot.username.isNotEmpty) 
        ? slot.username[0].toUpperCase() 
        : '?';

    return _buildAvatarBubble(
      url: slot.photoUrl,
      initial: initial,
      size: avatarSize,
    );
  }

  Widget _buildEmptySlot(int index) {
    return Stack(
      children: [
        Center(
          child: Icon(
            Icons.chair_alt_outlined,
            color: Colors.white.withOpacity(0.25),
            size: 28,
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Text(
            '${index + 1}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ─── CHAT ───

  Widget _buildChatSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChatTabRail(),
        Expanded(child: _buildChatMessages()),
      ],
    );
  }

  Widget _buildChatTabRail() {
    final tabs = ['All', 'Room', 'Chat'];
    return Container(
      width: 36,
      color: Colors.black.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(tabs.length, (i) {
          final isActive = _chatTab == i;
          return GestureDetector(
            onTap: () => setState(() => _chatTab = i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isActive ? const Color(0xFF6B5BEB) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChatMessages() {
    final visible = _messages.where((m) {
      if (_chatTab == 0) return true;
      if (_chatTab == 1) return m.isSystem;
      return !m.isSystem;
    }).toList();

    return Container(
      color: Colors.black.withOpacity(0.18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.builder(
        controller: _chatScrollController,
        itemCount: visible.length,
        itemBuilder: (context, index) => _buildBubble(visible[index]),
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration:
        BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Text(msg.text,
            style: const TextStyle(
                color: Color(0xFF4DFFB4), fontSize: 12, height: 1.4)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${msg.sender}: ',
              style: const TextStyle(
                  color: Color(0xFF9B8FFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            TextSpan(
                text: msg.text,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM BAR ───

  Widget _buildBottomBar() {
    final bool isSpeakerOrCoHost = widget.isHost ||
        (_participants.any(
                (p) => p.userId == _currentUserId && (p.seatNo > 0 || p.isCoHost)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.black.withOpacity(0.4),
      child: Row(
        children: [
          // Tools
          _buildBottomIconButton(
            icon: Icons.more_horiz,
            onTap: () {
              showAudioToolsBottomSheet(
                context,
                currentRoomId: widget.roomId,
                isHost: widget.isHost,
                musicManager: _musicPlayerManager,
                hostName: _roomData['hostName'] ?? 'Host',
              );
            },
          ),
          const SizedBox(width: 8),

          if (widget.isHost) ...[
            _buildBottomIconButton(
              icon: CupertinoIcons.person_add_solid,
              onTap: () {
                showAllRequestsBottomSheet(
                  context,
                  coHostRequests: _coHostRequests,
                  speakerRequests: _speakerRequests,
                  roomID: widget.roomId,
                  isMoveAllowed: _isMoveAllowed,
                  isSeatApprovalRequired: _isSeatApprovalRequired,
                );
              },
            ),
            const SizedBox(width: 8),
          ],

          // Gift
          _buildBottomIconButton(
            icon: CupertinoIcons.gift_fill,
            onTap: () {
              showGiftBottomSheet(
                context,
                roomId: widget.roomId,
                participants: _participants,
                hostId: _roomData['hostId'] ?? '',
              );
            },
          ),
          const SizedBox(width: 8),

          // Emoji
          _buildBottomIconButton(
            icon: CupertinoIcons.smiley,
            onTap: () => showEmojiBottomSheet(context, widget.roomId),
          ),
          const SizedBox(width: 8),

          // ── Mic toggle ──
          // Uses muteMode:true so stream stays published — instant toggle
          _buildBottomIconButton(
            icon: _isMicOn ? CupertinoIcons.mic_fill : CupertinoIcons.mic_off,
            color: _isMicOn ? Colors.white : Colors.red,
            onTap: () {
              final newMicState = !_isMicOn;

              // 1. Instant Zego toggle (muteMode keeps stream alive)
              _setMic(newMicState);
              setState(() => _isMicOn = newMicState);

              // 2. Background — backend sync (non-blocking)
              _roomApi.updateMuteState(widget.roomId, !newMicState).then((res) {
                if ((res == null || !res.status) && mounted) {
                  // Rollback if backend rejected
                  _setMic(!newMicState);
                  setState(() => _isMicOn = !newMicState);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mic update failed, reverted')),
                  );
                }
              });
            },
          ),
          const SizedBox(width: 8),

          // Chat input
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.send, color: Colors.white60, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ──────────────────────────── PARTICIPANT MODEL ────────────────────────────

class RoomParticipant_ {
  final String userId;
  final String userName;
  final String? userPicture;
  final int seatNo;
  final bool isCoHost;
  final bool isMuted;
  final ZegoUIKitUser? zegoUser;

  const RoomParticipant_({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.seatNo,
    required this.isCoHost,
    required this.isMuted,
    this.zegoUser,
  });

  factory RoomParticipant_.fromJoin(ParticipantInJoin p) {
    return RoomParticipant_(
      userId: p.userId,
      userName: p.userName,
      userPicture: p.userPicture,
      seatNo: p.seatNo,
      isCoHost: p.isCoHost,
      isMuted: p.isMuted,
    );
  }

  factory RoomParticipant_.fromParticipant(ParticipantInJoin p) {
    return RoomParticipant_(
      userId: p.userId,
      userName: p.userName,
      userPicture: p.userPicture,
      seatNo: p.seatNo,
      isCoHost: p.isCoHost,
      isMuted: p.isMuted,
    );
  }

  RoomParticipant_ copyWith({ZegoUIKitUser? zegoUser}) {
    return RoomParticipant_(
      userId: userId,
      userName: userName,
      userPicture: userPicture,
      seatNo: seatNo,
      isCoHost: isCoHost,
      isMuted: isMuted,
      zegoUser: zegoUser ?? this.zegoUser,
    );
  }
}