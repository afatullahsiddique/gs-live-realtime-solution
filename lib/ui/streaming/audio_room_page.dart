import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cute_live/core/utils/view_count.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../core/utils/links.dart';
import '../../core/widgets/auto_scroll_text.dart';
import '../../core/widgets/gift_image_widget.dart';
import '../../data/remote/firebase/app_services.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../data/remote/firebase/profile_services.dart';
import '../../data/local/secure_storage/secure_storage.dart';
import '../../data/remote/rest/models/room_response_model.dart';
import '../../data/remote/rest/room_api_service.dart';
import '../../navigation/routes.dart';
import '../video_streaming/bottomsheets/profile_info_bottomsheet.dart';
import 'bottomsheets/emoji_bottomsheet.dart';
import 'bottomsheets/gifts_bottomsheet.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/play_music_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';
import 'bottomsheets/audio_tools_bottomsheet.dart';

class CoHostRequest {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;

  CoHostRequest({required this.requestId, required this.userId, required this.userName, this.userPicture});

  factory CoHostRequest.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return CoHostRequest(
      requestId: key,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPicture: data['userPicture'],
    );
  }

  factory CoHostRequest.fromResponse(CohostRequestData data) {
    return CoHostRequest(
      requestId: data.requestId,
      userId: data.userId,
      userName: data.userName,
      userPicture: data.userPicture,
    );
  }
}

class SpeakerRequest {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;

  SpeakerRequest({required this.requestId, required this.userId, required this.userName, this.userPicture});

  factory SpeakerRequest.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return SpeakerRequest(
      requestId: key,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPicture: data['userPicture'],
    );
  }

  factory SpeakerRequest.fromResponse(Map<String, dynamic> data) {
    return SpeakerRequest(
      requestId: data['requestId'] ?? '',
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
  final int seatNo;
  final bool isCoHost;
  final bool isMuted;
  final ZegoUIKitUser? zegoUser;

  RoomParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.seatNo,
    required this.isCoHost,
    required this.isMuted,
    this.zegoUser,
  });

  factory RoomParticipant.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return RoomParticipant(
      userId: data['userId'] ?? key,
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

enum MessageType { text, gift, emoji }

class ChatMessage {
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String? iconUrl;

  ChatMessage({
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.iconUrl,
  });
}

class EmojiEvent {
  final String senderId;
  final String senderName;
  final String emojiUrl;
  final String emojiName;

  EmojiEvent({required this.senderId, required this.senderName, required this.emojiUrl, required this.emojiName});
}

class GiftOverlay {
  final int? luckyHitCount;
  final String senderName;
  final String? senderPicture;
  final String giftImageUrl;

  GiftOverlay({required this.senderName, this.senderPicture, required this.giftImageUrl, this.luckyHitCount});
}

class AudioRoomPage extends StatefulWidget {
  final String roomID;
  final bool isHost;
  final ZegoConfig? initialZegoConfig;

  const AudioRoomPage({
    super.key,
    required this.roomID,
    required this.isHost,
    this.initialZegoConfig,
  });

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> with SingleTickerProviderStateMixin {
  late MusicPlayerManager _musicPlayerManager;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  final roomApiService = GetIt.instance<RoomApiService>();
  final _secureStorage = GetIt.I<SecureStorage>();
  String _currentUserId = '';

  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _speakerRequestsSubscription;
  StreamSubscription? _coHostRequestsSubscription;
  Timer? _refreshTimer;
  StreamSubscription? _emojiSubscription;

  RoomModel? _roomModel;
  Map<String, dynamic> roomData = {};
  List<RoomParticipant> _participants = [];
  List<ChatMessage> _messages = [];
  List<SpeakerRequest> _speakerRequests = [];
  List<CoHostRequest> _coHostRequests = [];
  int _participantCount = 0;
  bool _isInitialized = false;
  bool _isMoveAllowed = true;
  bool _isSeatApprovalRequired = true;
  bool _roomDoesNotExist = false;
  String _currentUserName = "Me";
  String _roomNotice = "";

  Duration welcomeTime = Duration(milliseconds: 3500);

  Timer? _joinAnimationTimer;
  String? _newJoinerName;

  EmojiEvent? _currentEmojiEvent;
  Timer? _emojiTimer;

  GiftOverlay? _currentGiftOverlay;
  Timer? _giftOverlayTimer;

  String? _fullScreenGiftUrl;
  Timer? _fullScreenGiftTimer;

  late AnimationController _joinAnimationController;
  late Animation<Offset> _joinAnimationOffset;

  @override
  void initState() {
    super.initState();

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
        weight: 1.0,
      ),
    ]).animate(_joinAnimationController);

    _musicPlayerManager = MusicPlayerManager();

    _initialize();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();
    _participantsSubscription?.cancel();
    _speakerRequestsSubscription?.cancel();
    _coHostRequestsSubscription?.cancel();
    _refreshTimer?.cancel();
    _emojiSubscription?.cancel();
    _emojiTimer?.cancel();
    _giftOverlayTimer?.cancel();
    _fullScreenGiftTimer?.cancel();

    _chatController.dispose();
    _chatScrollController.dispose();
    _joinAnimationTimer?.cancel();

    _joinAnimationController.dispose();
    _musicPlayerManager.dispose();

    if (_isInitialized) {
      if (widget.isHost) {
        roomApiService.deleteRoom(widget.roomID);
      } else {
        roomApiService.leaveRoom(widget.roomID);
      }
      ZegoUIKit().leaveRoom();
      ZegoUIKit().logout();
      ZegoUIKit().uninit();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      print('🚀 [AUDIO_ROOM_PAGE] Initialization started for room ${widget.roomID}');
      final response = await roomApiService.getRoomInfo(widget.roomID);
      
      if (response == null || !response.status) {
        print('❌ [AUDIO_ROOM_PAGE] Room info NOT found or API error.');
        if (mounted) {
          setState(() {
            _roomDoesNotExist = true;
          });
        }
        return;
      }

      _roomModel = response.data.room;
      // Convert to Map for compatibility with existing code
      final room = _roomModel!;
      roomData = {
        'roomId': room.roomId,
        'hostId': room.hostId,
        'hostName': room.hostName,
        'hostPicture': room.hostPicture,
        'hostDisplayId': room.hostDisplayId,
        'isLocked': room.isLocked,
        'password': room.password,
        'participantCount': room.participantCount,
        'isMoveAllowed': room.isMoveAllowed,
        'isSeatApprovalRequired': room.isSeatApprovalRequired,
        'notice': room.notice,
      };

      final bool isLocked = room.isLocked;

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
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go(Routes.home.path);
        }
      }
    }
  }

  Future<void> _finishInitialization() async {
    if (!await _checkAudioPermissions()) {
      if (mounted) context.pop();
      return;
    }

    final user = await _secureStorage.getUser();
    if (user == null) {
      print('❌ [AUDIO_ROOM_PAGE] User not found in SecureStorage');
      if (mounted) context.go(Routes.login.path);
      return;
    }

    _currentUserId = user.id;
    _currentUserName = user.name;

    try {
      final userDoc = await ProfileService.getUserProfile(_currentUserId);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['displayName'] ?? user.name;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user name from profile service: $e");
    }

    final ZegoConfig? zegoConfigToUse = widget.initialZegoConfig ?? _roomModel?.zegoConfig;

    await ZegoUIKit().init(
      appID: zegoConfigToUse != null 
          ? (int.tryParse(zegoConfigToUse.appId.toString()) ?? await AppServices.getZegoAppId())
          : await AppServices.getZegoAppId(),
      appSign: zegoConfigToUse?.signId ?? await AppServices.getZegoAppSign(),
      scenario: ZegoScenario.Default,
    );

    ZegoUIKit().login(_currentUserId, _currentUserName);

    if (!widget.isHost) {
      print('🚀 [AUDIO_ROOM_PAGE] Calling joinRoom REST API...');
      final joinResponse = await roomApiService.joinRoom(widget.roomID);
      
      if (joinResponse != null && joinResponse.status) {
        print('✅ [AUDIO_ROOM_PAGE] REST Join Success');
        final zego = joinResponse.data.zegoConfig;
        
        // Populate participants from join response
        setState(() {
          _participants = joinResponse.data.participants.map((p) => RoomParticipant(
            userId: p.userId,
            userName: p.userName,
            userPicture: p.userPicture,
            seatNo: p.seatNo,
            isCoHost: p.isCoHost,
            isMuted: p.isMuted,
          )).toList();
          _participantCount = joinResponse.data.room.participantCount;
          _isMoveAllowed = joinResponse.data.room.isMoveAllowed;
          _isSeatApprovalRequired = joinResponse.data.room.isSeatApprovalRequired;
          _roomNotice = joinResponse.data.room.notice;
        });

        // Join Zego with token if available
        final int targetAppId = int.tryParse(zego.appId.toString()) ?? (await AppServices.getZegoAppId());
        
        // Re-init if appId is different? For now just ensure we have correct sign or token
        // If zego has signId, we might need it for re-init, but let's stick to token if present.
        
        await ZegoUIKit().joinRoom(zego.roomId ?? widget.roomID, token: zego.token ?? '');
        
        _sendJoinMessage();
        _showJoinAnimation(_currentUserName);
      } else {
        print('❌ [AUDIO_ROOM_PAGE] REST Join Failed: ${joinResponse?.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to join room: ${joinResponse?.message ?? "Unauthorized"}'))
          );
          context.pop();
          return;
        }
      }
    } else {
      await ZegoUIKit().joinRoom(
        widget.roomID, 
        token: zegoConfigToUse?.token ?? '',
      );
    }

    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().setAudioOutputToSpeaker(true);
    ZegoUIKit().startPlayAllAudioVideo();

    _setupListeners();
    _musicPlayerManager.initialize();
    setState(() => _isInitialized = true);

    // Start polling for updates
    _startPolling();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshRoomData();
      }
    });
  }

  Future<void> _refreshRoomData() async {
    try {
      // 1. Refresh Room Info (Participants, Seats, etc.)
      final response = await roomApiService.getRoomInfo(widget.roomID);
      if (response != null && response.status) {
        final room = response.data.room;
        if (mounted) {
          setState(() {
            _participants = room.participants.map((p) => RoomParticipant(
              userId: p.userId,
              userName: p.userName,
              userPicture: p.userPicture,
              seatNo: p.seatNo,
              isCoHost: p.isCoHost,
              isMuted: p.isMuted,
            )).toList();
            _participantCount = room.participantCount;
            _roomNotice = room.notice;
            _isMoveAllowed = room.isMoveAllowed;
            _isSeatApprovalRequired = room.isSeatApprovalRequired;
          });
        }
      }

      // 2. If Host, Refresh Co-Host Requests
      if (widget.isHost) {
        final requestsResponse = await roomApiService.getCohostRequests(widget.roomID);
        if (requestsResponse != null && requestsResponse.status) {
          if (mounted) {
            setState(() {
              _coHostRequests = requestsResponse.data.requests
                  .map((r) => CoHostRequest.fromResponse(r))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error refreshing room data: $e");
    }
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
    // Note: Firebase listeners are temporarily disabled to avoid permission errors during REST transition.
    // Future real-time updates should be implemented via REST polling or WebSockets.

    _messageSubscription = ZegoUIKit().getInRoomMessageStream().listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              userId: message.user.id,
              username: message.user.name,
              message: message.message,
              timestamp: DateTime.now(),
            ),
          );
          _scrollToBottom();
        });
      }
    });
  }

  void _showEmoji({
    required String senderId,
    required String senderName,
    required String emojiUrl,
    required String emojiName,
  }) {
    _emojiTimer?.cancel();
    setState(() {
      _currentEmojiEvent = EmojiEvent(
        senderId: senderId,
        senderName: senderName,
        emojiUrl: emojiUrl,
        emojiName: emojiName,
      );
    });

    _emojiTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentEmojiEvent = null;
        });
      }
    });
  }

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

  // Helper methods for emoji display on avatars
  bool _shouldShowEmoji(String userId) {
    return _currentEmojiEvent != null && _currentEmojiEvent!.senderId == userId;
  }

  Widget _buildEmojiOnAvatar(String userId, double size) {
    if (!_shouldShowEmoji(userId)) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: GiftImageWidget(imageUrl: _currentEmojiEvent!.emojiUrl, fit: BoxFit.contain),
    );
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
                  // TODO: Implement REST API for setting password
                  // await RoomService.setOrChangeRoomPassword(widget.roomID, password);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password management via REST is still under implementation.'), backgroundColor: Colors.orange),
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
                  // TODO: Implement REST API for removing password
                  // await RoomService.removeRoomPassword(widget.roomID);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Room password removal via REST is still under implementation.'), backgroundColor: Colors.orange),
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

  void _showGiftOverlay({
    required String senderName,
    String? senderPicture,
    required String giftAnimationUrl,
    required String giftImageUrl,
    bool isLuckyGift = false,
    int? hitCount,
  }) {
    _giftOverlayTimer?.cancel();

    setState(() {
      _currentGiftOverlay = GiftOverlay(
        senderName: senderName,
        senderPicture: senderPicture,
        giftImageUrl: giftImageUrl,
        luckyHitCount: hitCount,
      );

      if (!isLuckyGift) {
        _fullScreenGiftUrl = giftAnimationUrl;
      }
    });

    _giftOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentGiftOverlay = null;
        });
      }
    });
  }

  Widget _buildFullScreenGift() {
    if (_fullScreenGiftUrl == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Center(
              child: Transform.scale(scale: value, child: child),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Colors.pink.withOpacity(0.3), Colors.transparent]),
          ),
          child: GiftImageWidget(
            imageUrl: _fullScreenGiftUrl!,
            fit: BoxFit.contain,
            isFullScreenAnimation: true,
            onAnimationComplete: () {
              if (mounted) {
                setState(() {
                  _fullScreenGiftUrl = null;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGiftOverlay() {
    if (_currentGiftOverlay == null) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.5 - 40,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900.withOpacity(0.95), Colors.pink.shade700.withOpacity(0.95)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.6), blurRadius: 15, spreadRadius: 1)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sender's picture
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 4, spreadRadius: 0.5)],
                    ),
                    child: ClipOval(
                      child:
                          _currentGiftOverlay!.senderPicture != null && _currentGiftOverlay!.senderPicture!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _currentGiftOverlay!.senderPicture!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 18),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Name and gift text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentGiftOverlay!.senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentGiftOverlay!.luckyHitCount != null
                            ? 'sent ${_currentGiftOverlay!.luckyHitCount} LUCKY gift!'
                            : 'sent a gift',
                        style: TextStyle(
                          color: _currentGiftOverlay!.luckyHitCount != null ? Colors.yellow.shade200 : Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Gift icon
                  CachedNetworkImage(
                    imageUrl: getFullUrl(_currentGiftOverlay!.giftImageUrl),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.card_giftcard, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    if (_roomDoesNotExist) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                  child: const Icon(Icons.link_off_rounded, size: 60, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Room Ended",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "The live session you are looking for\nhas ended or does not exist.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () => context.go(Routes.home.path),
                  child: const Text("Go to Homepage", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        // Check if keyboard is open
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          // Keyboard is open, just close it
          FocusManager.instance.primaryFocus?.unfocus();
          return false; // Don't pop the route
        }

        // Keyboard is closed, show exit confirmation
        final shouldExit = await _showExitConfirmationDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Builder(
          builder: (context) {
            String? backgroundUrl = _isInitialized ? roomData['backgroundUrl'] : null;

            return Stack(
              children: [
                // Always show gradient background
                if (backgroundUrl == null)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/room_bg/audio.jpeg',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    ),
                  )
                else
                  // Show custom skin background if set
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: backgroundUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),

                SafeArea(
                  child: _isInitialized
                      ? Stack(
                          children: [
                            Stack(
                              children: [
                                Column(
                                  children: [
                                    _buildAppBar(),
                                    _buildHostStatsRow(),
                                    Column(children: [_buildStreamerProfile(), _buildSeatsGrid()]),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 60),
                                        child: Stack(children: [_buildChatSection(), _buildJoinCallOverlay()]),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(bottom: 0, left: 0, right: 0, child: _buildChatInput()),
                              ],
                            ),
                            Center(child: _buildJoinAnimationOverlay()),
                            _buildFullScreenGift(),
                            _buildGiftOverlay(),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.pink)),
                ),
              ],
            );
          },
        ),
      ),
    );
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

  Widget _buildAppBar() {
    final String hostId = roomData['hostId'] ?? '';
    final String currentUserId = _currentUserId;
    final bool isGuest = !widget.isHost && hostId != currentUserId;

    final guestParticipants = _participants.where((p) => p.userId != hostId).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 6.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (hostId == currentUserId) return;
              showProfileInfoBottomSheet(context, userId: hostId, hostId: hostId, roomId: widget.roomID);
            },
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundImage: NetworkImage(roomData['hostPicture'] ?? '')),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: AutoScrollText(
                        text: roomData["hostName"] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: ProfileService.getUserProfileStream(hostId),
                      builder: (context, snapshot) {
                        String id = '';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          id = data['displayId'] ?? "";
                        }
                        return Text('ID: ${id}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12));
                      },
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
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await ProfileService.followUser(hostId);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.pink.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                );
              },
            ),
          const Spacer(),
          _buildParticipantAvatars(guestParticipants),
          GestureDetector(
            onTap: () {
              showParticipantsBottomSheet(
                context,
                participants: _participants,
                currentUserId: _currentUserId,
                hostId: roomData['hostId'],
                roomId: widget.roomID,
              );
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
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, size: 28, color: Colors.grey),
            onPressed: _showExitConfirmationDialog,
            tooltip: 'Exit Room',
          ),
        ],
      ),
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

  Widget _buildHostStatsRow() {
    final String hostId = roomData['hostId'] ?? '';
    if (hostId.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 8.0, 8.0),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: ProfileService.getUserProfileStream(hostId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Row(
                  children: [
                    _buildStatChip(Icons.star_rounded, "...", Colors.grey.shade700),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.diamond_outlined, "...", Colors.grey.shade700),
                  ],
                );
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final int diamondCount = data['diamonds'] ?? 0;

              return Row(
                children: [_buildStatChip(Icons.diamond_outlined, formatViewCount(diamondCount), Colors.cyan.shade300)],
              );
            },
          ),
          if (widget.isHost)
            IconButton(
              icon: Icon(
                (roomData['isLocked'] ?? false) ? Icons.lock : Icons.lock_open,
                color: (roomData['isLocked'] ?? false) ? Colors.pink : Colors.white,
                size: 16,
              ),
              onPressed: _showPasswordManagementDialog,
              tooltip: 'Room Security',
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatars(List<RoomParticipant> participants) {
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

  Widget _buildStreamerProfile() {
    RoomParticipant? host;
    try {
      host = _participants.firstWhere((p) => p.userId == roomData['hostId']);
    } catch (e) {
      host = null;
    }

    RoomParticipant? coHost;
    try {
      coHost = _participants.firstWhere((p) => p.isCoHost && p.userId != roomData['hostId'] && (p.seatNo <= 1));
    } catch (e) {
      coHost = null;
    }

    Widget buildStreamerSeat({
      required String? imageUrl,
      required String? name,
      required bool isMuted,
      required String? userId,
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
              _buildEmojiOnAvatar(userId ?? '', size),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: AutoScrollText(
              text: name ?? "Unknown",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHost ? Colors.pink : Colors.white,
                fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
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
          GestureDetector(
            onTap: roomData['hostId'] == _currentUserId
                ? null
                : () {
                    showProfileInfoBottomSheet(
                      context,
                      userId: roomData['hostId'],
                      hostId: roomData['hostId'],
                      roomId: widget.roomID,
                    );
                  },
            child: buildStreamerSeat(
              imageUrl: roomData['hostPicture'],
              name: roomData['hostName'],
              isMuted: host?.isMuted ?? true,
              userId: roomData['hostId'],
              isHost: true,
            ),
          ),
          const SizedBox(width: 30),
          if (coHost != null)
            GestureDetector(
              onTap: coHost.userId != _currentUserId
                  ? () {
                      showProfileInfoBottomSheet(
                        context,
                        userId: coHost!.userId,
                        hostId: roomData['hostId'],
                        roomId: widget.roomID,
                      );
                    }
                    : () async {
                      try {
                        // TODO: Implement REST API for stepping down
                        // await RoomService.stepDownFromCoHost(widget.roomID);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stepping down via REST is still under implementation.'))
                        );
                        ZegoUIKit().turnMicrophoneOn(false);
                      } catch (e) {
                        debugPrint("Error stepping down from co-host: $e");
                      }
                    },
              child: buildStreamerSeat(
                imageUrl: coHost.userPicture,
                name: coHost.userName,
                isMuted: coHost.isMuted,
                userId: coHost.userId,
                isHost: false,
              ),
            )
          else
            Builder(
              builder: (context) {
                final currentUserParticipant = _participants.firstWhere(
                  (p) => p.userId == _currentUserId,
                  orElse: () => RoomParticipant(userId: '', userName: '', seatNo: -1, isCoHost: false, isMuted: true),
                );
                final bool canRequestCoHost = !widget.isHost && !currentUserParticipant.isCoHost;
                return GestureDetector(
                  onTap: !canRequestCoHost
                      ? null
                      : () async {
                        try {
                          // TODO: Implement REST API for request
                          // await RoomService.requestToBeCoHost(widget.roomID);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Co-host request via REST is still under implementation.'),
                                backgroundColor: Colors.orange,
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
    final String currentUserId = _currentUserId;

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
        final seatNo = index + 2;
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
    final currentUserId = _currentUserId;
    RoomParticipant? currentUserParticipant;
    try {
      currentUserParticipant = _participants.firstWhere((p) => p.userId == currentUserId);
    } catch (e) {
      currentUserParticipant = null;
    }

    final bool canInteract = !widget.isHost && currentUserParticipant != null;
    final bool isListener = canInteract && currentUserParticipant.seatNo == -1 && !currentUserParticipant.isCoHost;
    final bool isSpeakerOrCoHost =
        canInteract && (currentUserParticipant.seatNo > 0 || currentUserParticipant.isCoHost);

    final bool showJoinIcon = !_isSeatApprovalRequired && isListener;

    IconData icon = Icons.event_seat;
    Color iconColor = canInteract ? Colors.pink : Colors.grey.shade800;

    return GestureDetector(
      onTap: () async {
        if (!canInteract) return;

        try {
          if (isListener) {
            if (_isSeatApprovalRequired) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap the \'Join Call\' button to request a seat.'),
                  backgroundColor: Colors.pink,
                ),
              );
            } else {
              print('🚀 [AUDIO_ROOM_PAGE] Calling takeSeat REST API for seat $seatNo...');
              final takeSeatResponse = await roomApiService.takeSeat(widget.roomID, seatNo);
              if (takeSeatResponse != null && takeSeatResponse.status) {
                print('✅ [AUDIO_ROOM_PAGE] REST Take Seat Success');
                ZegoUIKit().turnMicrophoneOn(true);
              } else {
                print('❌ [AUDIO_ROOM_PAGE] REST Take Seat Failed: ${takeSeatResponse?.message}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to take seat: ${takeSeatResponse?.message ?? "Error"}'))
                  );
                }
              }
            }
          } else if (isSpeakerOrCoHost) {
            if (_isMoveAllowed) {
              print('🚀 [AUDIO_ROOM_PAGE] Calling move (takeSeat) REST API for seat $seatNo...');
              final moveResponse = await roomApiService.takeSeat(widget.roomID, seatNo);
              if (moveResponse != null && moveResponse.status) {
                print('✅ [AUDIO_ROOM_PAGE] REST Move Success');
              } else {
                print('❌ [AUDIO_ROOM_PAGE] REST Move Failed: ${moveResponse?.message}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to move: ${moveResponse?.message ?? "Error"}'))
                  );
                }
              }
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
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                if (showJoinIcon)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
              ],
            ),
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
          ? () {
              showProfileInfoBottomSheet(
                context,
                userId: participant.userId,
                hostId: roomData['hostId'],
                roomId: widget.roomID,
              );
            }
          : () async {
              try {
                // TODO: Implement REST API for leaving seat
                // await RoomService.leaveSeat(widget.roomID);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leaving seat via REST is still under implementation.'))
                );
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
              _buildEmojiOnAvatar(participant.userId, 55),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: AutoScrollText(
              text: participant.userName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10),
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

  Widget _buildJoinCallOverlay() {
    final String currentUserId = _currentUserId;
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
      visible: isListener && _isSeatApprovalRequired,
      child: Positioned(
        bottom: 8,
        right: 24,
        child: GestureDetector(
          onTap: () async {
            try {
              final response = await roomApiService.requestCohost(widget.roomID);
              if (mounted) {
                if (response != null && response.status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request to co-host sent!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send request: ${response?.message ?? "Error"}')),
                  );
                }
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 150,
                    child: Text(
                      "Any sexual or violation content is strictly prohibited. All violator will be banned. Do not expose your personal info such phone or location.",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  if (_roomNotice.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign, color: Colors.pink, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _roomNotice,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final messageIndex = index - 1;
          final m = _messages[messageIndex];

          return Padding(padding: const EdgeInsets.only(bottom: 6), child: _buildChatMessage(m));
        },
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage m) {
    // If it's an emoji message, show it large like WhatsApp
    if (m.type == MessageType.emoji && m.iconUrl != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () {
            showProfileInfoBottomSheet(
              context,
              userId: m.userId,
              hostId: roomData['hostId'] ?? '',
              roomId: widget.roomID,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username with level badge
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                ),
              ),
              Text(
                m.username,
                style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(width: 8),
              // Large emoji
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: GiftImageWidget(imageUrl: m.iconUrl!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Regular text and gift messages
    return Column(
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
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                ),
              ),
              Text(
                "${m.username} ",
                style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              // Show message based on type
              if (m.type == MessageType.text)
                Flexible(
                  child: Text(m.message, style: const TextStyle(color: Colors.white, fontSize: 15)),
                )
              else if (m.type == MessageType.gift) ...[
                Text(m.message, style: const TextStyle(color: Colors.white, fontSize: 15)),
                if (m.iconUrl != null) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: GiftImageWidget(imageUrl: m.iconUrl!, fit: BoxFit.contain),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    final String currentUserId = _currentUserId;
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
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                showAudioToolsBottomSheet(
                  context,
                  isHost: widget.isHost,
                  musicManager: _musicPlayerManager,
                  currentRoomId: widget.roomID,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
              ),
            ),
          ),
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => showAllRequestsBottomSheet(
                  context,
                  coHostRequests: _coHostRequests,
                  speakerRequests: _speakerRequests,
                  roomID: widget.roomID,
                  isMoveAllowed: _isMoveAllowed,
                  isSeatApprovalRequired: _isSeatApprovalRequired,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
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
          if (isSpeakerOrCoHost)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  final newMuteState = !isCurrentlyMuted;
                  // TODO: Implement REST API for toggle mute
                  // RoomService.toggleMuteState(widget.roomID, newMuteState);
                  ZegoUIKit().turnMicrophoneOn(!newMuteState);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: Icon(
                    isCurrentlyMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                    color: isCurrentlyMuted ? Colors.white : Colors.pink,
                    size: 22,
                  ),
                ),
              ),
            ),
          if (isSpeakerOrCoHost)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  showEmojiBottomSheet(context, widget.roomID);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: const Icon(CupertinoIcons.smiley, color: Colors.white, size: 22),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                showGiftBottomSheet(
                  context,
                  roomId: widget.roomID,
                  participants: _participants,
                  hostId: roomData['hostId'] ?? '',
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 20),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _chatController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  fillColor: Colors.black.withOpacity(0.2),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
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

  void _addChatMessage({
    required String userId,
    required String username,
    required String message,
    required MessageType type,
    String? iconUrl,
  }) {
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            userId: userId,
            username: username,
            message: message,
            timestamp: DateTime.now(),
            type: type,
            iconUrl: iconUrl,
          ),
        );
        _scrollToBottom();
      });
    }
  }

  void _sendMessage() async {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty) return;

    try {
      await ZegoUIKit().sendInRoomMessage(messageText);
      setState(() {
        _messages.add(
          ChatMessage(
            userId: _currentUserId,
            username: _currentUserName,
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
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              userId: _currentUserId,
              username: _currentUserName,
              message: messageText,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending join message: $e');
    }
  }
}
