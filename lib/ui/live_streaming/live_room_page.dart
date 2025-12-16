import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:collection/collection.dart';

import '../../core/utils/view_count.dart';
import '../../core/widgets/auto_scroll_text.dart';
import '../../data/remote/firebase/app_services.dart';
import '../../data/remote/firebase/live_streaming_services.dart';
import '../../data/remote/firebase/profile_services.dart';
import '../../navigation/routes.dart';
import '../streaming/bottomsheets/gifts_bottomsheet.dart';
import '../video_streaming/bottomsheets/invite_pk_bottomsheet.dart';
import 'bottomsheets/emoji_bottomsheet.dart';
import 'bottomsheets/live_tools_bottomsheet.dart';
import 'bottomsheets/participants_bottomsheet.dart';
import 'bottomsheets/requests_bottomsheet.dart';

import '../../ui/streaming/bottomsheets/play_music_bottomsheet.dart';

// --- MODELS ---
class LiveStreamParticipant {
  final String userId;
  final String userName;
  final String? userPicture;
  final bool isMuted;
  final bool isCameraOn;

  LiveStreamParticipant({
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.isMuted,
    required this.isCameraOn,
  });

  factory LiveStreamParticipant.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return LiveStreamParticipant(
      userId: data['userId'] ?? key,
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

  factory JoinRequest.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return JoinRequest(
      requestId: key,
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

class EmojiEvent {
  final String senderId;
  final String senderName;
  final String emojiUrl;
  final String emojiName;

  EmojiEvent({required this.senderId, required this.senderName, required this.emojiUrl, required this.emojiName});
}

// --- PAGE ---
class LiveStreamPage extends StatefulWidget {
  final String roomID;
  final bool isHost;

  const LiveStreamPage({super.key, required this.roomID, required this.isHost});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> with SingleTickerProviderStateMixin {
  late MusicPlayerManager _musicPlayerManager;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream Subscriptions
  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _joinRequestsSubscription;
  StreamSubscription? _emojiSubscription;
  StreamSubscription? _pkInvitesSubscription;
  StreamSubscription? _sentPKInvitesSubscription;
  StreamSubscription? _opponentParticipantsSubscription;
  StreamSubscription? _globalRandomPKInvitesSubscription;
  BuildContext? _currentRandomPKDialogContext;

  // State Variables
  late Map<String, dynamic> roomData;
  List<LiveStreamParticipant> _participants = [];
  List<ChatMessage> _messages = [];
  List<JoinRequest> _joinRequests = [];
  List<PKInvite> _pendingInvites = [];
  int _participantCount = 0;
  bool _isInitialized = false;
  late bool _isJoined;
  bool _roomDoesNotExist = false;
  String _currentUserName = "Me";
  final Set<String> _dialogsShownForInviteIds = {};
  String _roomNotice = "";
  ZegoVoiceChangerPreset _currentVoicePreset = ZegoVoiceChangerPreset.None;
  bool _isSpeakerOn = true;

  // PK State Variables
  bool _isPKMode = false;
  Map<String, dynamic> _pkState = {};
  List<LiveStreamParticipant> _opponentParticipants = [];

  Timer? _pkTimer;
  String _pkTimerDisplay = "00:00";

  int _pkScoreBlue = 0;
  int _pkScoreRed = 0;

  bool _isStartingPKAnimation = false;

  // Emoji State
  EmojiEvent? _currentEmojiEvent;
  Timer? _emojiTimer;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.isHost;
    _musicPlayerManager = MusicPlayerManager();
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
    _emojiSubscription?.cancel();
    _emojiTimer?.cancel();
    _pkInvitesSubscription?.cancel();
    _sentPKInvitesSubscription?.cancel();
    _opponentParticipantsSubscription?.cancel();
    _globalRandomPKInvitesSubscription?.cancel();
    _pkTimer?.cancel();

    _chatController.dispose();
    _chatScrollController.dispose();
    _musicPlayerManager.dispose();

    if (_isInitialized) {
      if (widget.isHost) {
        if (_isPKMode && _pkState.containsKey('opponentRoomId')) {
          LiveStreamService.endPKBattle(widget.roomID, _pkState['opponentRoomId']);

          String opponentHostId = _pkState['opponentHostId'] ?? '';
          if (opponentHostId.isNotEmpty) {
            ZegoUIKit().stopPlayAnotherRoomAudioVideo(opponentHostId);
          }
        }
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
      final permissions = widget.isHost ? [Permission.microphone, Permission.camera] : [Permission.microphone];
      if (!await _checkPermissions(permissions)) {
        if (mounted) context.pop();
        return;
      }

      final roomSnapshot = await LiveStreamService.getRoomInfo(widget.roomID);
      if (!roomSnapshot.exists) {
        if (mounted) {
          setState(() {
            _roomDoesNotExist = true;
          });
        }
        return;
      }

      roomData = Map<String, dynamic>.from(roomSnapshot.value as Map);
      _musicPlayerManager.initialize();
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
      appID: await AppServices.getZegoAppId(),
      appSign: await AppServices.getZegoAppSign(),
      scenario: ZegoScenario.Default,
    );

    ZegoUIKit().updateVideoViewMode(true);

    final currentUser = _auth.currentUser!;
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
        _currentUserName = currentUser.displayName ?? "Unknown";
      });
    }

    ZegoUIKit().login(currentUser.uid, _currentUserName);
    await ZegoUIKit().joinRoom(widget.roomID);

    ZegoUIKit().turnMicrophoneOn(widget.isHost);
    ZegoUIKit().turnCameraOn(widget.isHost);
    ZegoUIKit().setAudioOutputToSpeaker(true);

    if (widget.isHost) {
      await LiveStreamService.toggleCameraState(widget.roomID, true);
    }

    _setupListeners();
    setState(() => _isInitialized = true);
  }

  void _startPKBattleSequence(Map<String, dynamic> newPKState) {
    setState(() {
      _pkState = newPKState;
    });

    if (!mounted) return;

    debugPrint("PK Animation finished. Starting PK logic.");

    if (widget.isHost) {
      final hostId = _auth.currentUser!.uid;
      LiveStreamService.demoteAllParticipantsToViewers(widget.roomID, hostId);
    }

    if (widget.isHost && newPKState['role'] == 'sender') {
      String opponentRoomId = newPKState['opponentRoomId'] ?? '';
      String opponentHostId = newPKState['opponentHostId'] ?? '';
      if (opponentRoomId.isNotEmpty && opponentHostId.isNotEmpty) {
        debugPrint("Sender is starting to play opponent's stream: $opponentHostId");
        ZegoUIKit().startPlayAnotherRoomAudioVideo(opponentRoomId, opponentHostId);
      }
    }

    final dynamic pkEndTimeValue = newPKState['pkEndTime'];
    if (pkEndTimeValue != null) {
      final DateTime pkEndTime = DateTime.fromMillisecondsSinceEpoch(pkEndTimeValue as int);
      _startPKTimer(pkEndTime);
    }

    _opponentParticipantsSubscription?.cancel();
    _opponentParticipantsSubscription = LiveStreamService.getRoomParticipants(newPKState['opponentRoomId']).listen((
      event,
    ) {
      if (!event.snapshot.exists) {
        if (mounted) setState(() => _opponentParticipants = []);
        return;
      }

      final participantsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final newOpponentParticipants = participantsMap.entries
          .map((entry) => LiveStreamParticipant.fromRTDB(entry.key, entry.value))
          .toList();

      if (mounted) {
        setState(() {
          _opponentParticipants = newOpponentParticipants;
        });
      }
    });

    setState(() async {
      _isPKMode = true;
      await Future.delayed(Duration(seconds: 1));
      _isStartingPKAnimation = true;
      await Future.delayed(Duration(seconds: 3));
      _isStartingPKAnimation = false;
    });
  }

  void _setupListeners() {
    _roomSubscription = LiveStreamService.getRoomStream(widget.roomID).listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          roomData = data;
          _participantCount = roomData['participantCount'] ?? 0;
          _roomNotice = roomData['notice'] ?? "";
        });

        final newPKState = data['pkState'] != null
            ? Map<String, dynamic>.from(data['pkState'] as Map)
            : <String, dynamic>{'isPK': false};

        final bool isNowInPK = newPKState['isPK'] == true;

        if (isNowInPK && !_isPKMode) {
          if (!_isStartingPKAnimation) {
            _startPKBattleSequence(newPKState);
          }
        } else if (!isNowInPK && _isPKMode) {
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
            ChatMessage(username: message.user.name, message: message.message, timestamp: DateTime.now()),
          );
          _scrollToNewestMessage();
        });
      }
    });

    _participantsSubscription = LiveStreamService.getRoomParticipants(widget.roomID).listen((event) {
      if (!event.snapshot.exists) {
        if (mounted) setState(() => _participants = []);
        return;
      }
      final participantsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final newParticipants = participantsMap.entries
          .map((entry) => LiveStreamParticipant.fromRTDB(entry.key, entry.value))
          .toList();

      final currentUser = _auth.currentUser!;
      final isNowJoined = newParticipants.any((p) => p.userId == currentUser.uid);

      if (isNowJoined && !_isJoined) {
        debugPrint("Join request approved! Starting local audio stream.");
        ZegoUIKit().turnMicrophoneOn(true);
      }

      if (mounted) {
        setState(() {
          _participants = newParticipants;
          _isJoined = isNowJoined;
        });
      }
    });

    _emojiSubscription = LiveStreamService.getEmojiStream(widget.roomID).listen((event) {
      if (!mounted || !event.snapshot.exists) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final timestamp = data['timestamp'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp < 5000) {
        _showEmoji(
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          emojiUrl: data['emojiUrl'] ?? '',
          emojiName: data['emojiName'] ?? '',
        );
      }
    });

    if (widget.isHost) {
      _joinRequestsSubscription = LiveStreamService.getJoinRequestsStream(widget.roomID).listen((event) {
        if (!event.snapshot.exists) {
          if (mounted) setState(() => _joinRequests = []);
          return;
        }
        final requestsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final requests = requestsMap.entries.map((entry) => JoinRequest.fromRTDB(entry.key, entry.value)).toList();
        if (mounted) setState(() => _joinRequests = requests);
      });

      _pkInvitesSubscription = LiveStreamService.getPKInvitesStream(widget.roomID).listen((invites) {
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

      _globalRandomPKInvitesSubscription = LiveStreamService.getGlobalRandomPKInvitesStream().listen((invites) {
        if (invites.isEmpty) return;

        for (final invite in invites) {
          if (invite.senderRoomId == widget.roomID) continue;
          if (_dialogsShownForInviteIds.contains(invite.id)) continue;

          _dialogsShownForInviteIds.add(invite.id);

          if (_currentRandomPKDialogContext != null) {
            Navigator.of(_currentRandomPKDialogContext!).pop();
            _currentRandomPKDialogContext = null;
          }

          _showGlobalRandomPKInviteDialog(invite);
        }
      });

      _sentPKInvitesSubscription = LiveStreamService.getSentPKInvitesStream(widget.roomID).listen((acceptedInvites) {
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
          LiveStreamService.endPKBattle(widget.roomID, _pkState['opponentRoomId']);
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

  Future<void> _showGlobalRandomPKInviteDialog(PKInvite invite) async {
    int remainingSeconds = 5;
    late void Function(void Function()) builderRef;
    Timer? autoCloseTimer;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _currentRandomPKDialogContext = dialogContext;

        autoCloseTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
          if (remainingSeconds <= 1) {
            timer.cancel();
            _currentRandomPKDialogContext = null;
            Navigator.of(dialogContext).maybePop();
          } else {
            remainingSeconds--;
            builderRef(() {});
          }
        });

        return StatefulBuilder(
          builder: (ctx, setState) {
            builderRef = setState;
            return AlertDialog(
              backgroundColor: const Color(0xFF2d1b2b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Text(
                    'Random PK Invitation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${remainingSeconds}s',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              content: Text(
                '${invite.senderHostName} wants to start a '
                '${invite.durationInMinutes}-minute PK. What do you want to do?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _currentRandomPKDialogContext = null;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Ignore', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    _currentRandomPKDialogContext = null;
                    Navigator.of(dialogContext).pop();

                    try {
                      await LiveStreamService.acceptGlobalRandomPKInvite(widget.roomID, invite);
                      ZegoUIKit().startPlayAnotherRoomAudioVideo(invite.senderRoomId, invite.senderHostId);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    autoCloseTimer?.cancel();
    _currentRandomPKDialogContext = null;
  }

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
          '${invite.senderHostName} wants to start a ${invite.durationInMinutes}-minute PK. What do you want to do?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              LiveStreamService.rejectPKInvite(widget.roomID, invite);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();

              LiveStreamService.acceptPKInvite(widget.roomID, invite);
              ZegoUIKit().startPlayAnotherRoomAudioVideo(invite.senderRoomId, invite.senderHostId);
            },
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  bool _shouldShowEmoji(String userId) {
    return _currentEmojiEvent != null && _currentEmojiEvent!.senderId == userId;
  }

  Widget _buildEmojiOnAvatar(String userId, double size) {
    if (!_shouldShowEmoji(userId)) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Image.network(_currentEmojiEvent!.emojiUrl, fit: BoxFit.contain),
      ),
    );
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
        final shouldExit = await _showExitConfirmationDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (!_isPKMode)
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
            if (_isInitialized)
              _isPKMode ? _buildPKModeLayout() : _buildStandardModeOverlay()
            else
              const SizedBox.shrink(),
            Visibility(visible: _isStartingPKAnimation, child: _buildPKStartingAnimation()),
          ],
        ),
      ),
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
          child: Column(
            children: [
              Expanded(flex: 1, child: _buildChatSection()),
              SafeArea(top: false, child: _buildChatInput()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardModeOverlay() {
    return Column(
      children: [
        _buildAppBar(),
        _buildHostStatsRow(),
        Expanded(
          child: Stack(
            children: [
              Align(alignment: Alignment.bottomCenter, child: _buildChatSection()),
              _buildJoinCallOverlay(),
            ],
          ),
        ),
        SafeArea(top: false, child: _buildChatInput()),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 6.0),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(roomData['hostPicture'] ?? '')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                      SizedBox(
                        width: 120,
                        child: AutoScrollText(
                          text: roomData["hostName"],
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ID: ${roomData['hostDisplayId']}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
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
                return Row(children: [_buildStatChip(Icons.diamond_outlined, "...", Colors.grey.shade700)]);
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final int diamondCount = data['diamonds'] ?? 0;

              return Row(
                children: [_buildStatChip(Icons.diamond_outlined, formatViewCount(diamondCount), Colors.cyan.shade300)],
              );
            },
          ),
          const Spacer(),
        ],
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

  Widget _buildHostVideo(LiveStreamParticipant host) {
    if (host.isCameraOn) {
      final zegoUser = ZegoUIKit().getUser(host.userId);
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
                backgroundImage: host.userPicture != null && host.userPicture!.isNotEmpty
                    ? NetworkImage(host.userPicture!)
                    : null,
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

  Widget _buildGuestAvatar(LiveStreamParticipant guest) {
    final borderRadius = BorderRadius.circular(10.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  image: (guest.userPicture != null && guest.userPicture!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(guest.userPicture!), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey.shade800,
                ),
                child: (guest.userPicture == null || guest.userPicture!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              if (guest.isMuted)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.mic_off, color: Colors.white, size: 30),
                ),
              _buildEmojiOnAvatar(guest.userId, 80),
            ],
          ),
        ),
      ),
    );
  }

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
    return Stack(
      children: [
        Positioned.fill(
          child: host != null
              ? Stack(
                  children: [
                    _buildHostVideo(host),
                    if (_shouldShowEmoji(host.userId))
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: Image.network(_currentEmojiEvent!.emojiUrl, fit: BoxFit.contain),
                        ),
                      ),
                  ],
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text('Waiting for host...', style: TextStyle(color: Colors.white)),
                  ),
                ),
        ),
        Positioned(
          top: 180,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: guests.map((guest) => _buildGuestAvatar(guest)).toList(),
          ),
        ),
      ],
    );
  }

  // FIXED: PK Video layout with proper positioning using Row and BoxFit.cover
  Widget _buildPKVideoLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildTeamHost(participants: _participants, hostName: roomData['hostName'] ?? 'Host A'),
        ),
        Expanded(
          child: _buildTeamHost(
            participants: _opponentParticipants,
            hostName: _pkState['opponentHostName'] ?? 'Host B',
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHost({required List<LiveStreamParticipant> participants, required String hostName}) {
    if (participants.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text('Waiting for $hostName...', style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final host = participants.first;
    return _buildHostVideoForPK(host);
  }

  // FIXED: Host video for PK with BoxFit.cover for no black bars
  Widget _buildHostVideoForPK(LiveStreamParticipant host) {
    if (host.isCameraOn) {
      final zegoUser = ZegoUIKit().getUser(host.userId);
      if (zegoUser != null) {
        return SizedBox.expand(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: ValueListenableBuilder<Size>(
                valueListenable: ZegoUIKit().getVideoSizeNotifier(host.userId),
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
    return Container(
      color: Colors.black,
      child: Center(
        child: CircleAvatar(
          radius: 40,
          backgroundImage: host.userPicture != null && host.userPicture!.isNotEmpty
              ? NetworkImage(host.userPicture!)
              : null,
          child: host.userPicture == null || host.userPicture!.isEmpty
              ? const Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildJoinCallOverlay() {
    return Visibility(
      visible: !_isJoined && !widget.isHost,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 20),
          child: GestureDetector(
            onTap: () async {
              try {
                await LiveStreamService.requestToJoin(widget.roomID);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request sent. Wait for host approval.'),
                      backgroundColor: Colors.pink,
                    ),
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
                    'Join Audio',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.25,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withOpacity(0.2)),
      child: ListView.builder(
        reverse: true,
        controller: _chatScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length + 1,
        itemBuilder: (context, index) {
          if (index == _messages.length) {
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

          // Chat messages
          final m = _messages[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
    LiveStreamParticipant? currentUserParticipant;
    if (_isJoined) {
      try {
        currentUserParticipant = _participants.firstWhere((p) => p.userId == _auth.currentUser!.uid);
      } catch (e) {
        currentUserParticipant = null;
      }
    }
    final bool isCurrentlyMuted = currentUserParticipant?.isMuted ?? true;
    final int totalRequests = _joinRequests.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                showLiveToolsBottomSheet(
                  context,
                  isHost: widget.isHost,
                  currentRoomId: widget.roomID,
                  hostName: roomData['hostName'] ?? 'Host',
                  pendingInvites: _pendingInvites,
                  musicManager: _musicPlayerManager,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
              ),
            ),
          ),

          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                      child: const Icon(CupertinoIcons.person_add_solid, color: Colors.white, size: 20),
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
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      ZegoUIKit().turnMicrophoneOn(false);
                      await LiveStreamService.leaveRoom(widget.roomID);
                    } catch (e) {
                      debugPrint("Error leaving call: $e");
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 20),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  final newMuteState = !isCurrentlyMuted;
                  LiveStreamService.toggleMuteState(widget.roomID, newMuteState);
                  ZegoUIKit().turnMicrophoneOn(!newMuteState);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: Icon(
                    isCurrentlyMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic_fill,
                    color: isCurrentlyMuted ? Colors.white : Colors.pink,
                    size: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  showVideoLiveEmojiBottomSheet(context, widget.roomID);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                  child: const Icon(CupertinoIcons.smiley, color: Colors.white, size: 20),
                ),
              ),
            ),
          ] else
            const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                final convertedParticipants = _participants.map((p) {
                  return _ConvertedParticipant(userId: p.userId, userName: p.userName, userPicture: p.userPicture);
                }).toList();

                showGiftBottomSheet(
                  context,
                  roomId: widget.roomID,
                  participants: convertedParticipants,
                  hostId: roomData['hostId'] ?? '',
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
                child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 18),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
              ),
              child: TextField(
                controller: _chatController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              child: const Icon(Icons.send, color: Colors.white, size: 18),
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

class _ConvertedParticipant {
  final String userId;
  final String userName;
  final String? userPicture;

  _ConvertedParticipant({required this.userId, required this.userName, this.userPicture});
}
