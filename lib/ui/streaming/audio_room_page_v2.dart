import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';

class AudioRoomPage extends StatefulWidget {
  final String roomID;
  final String userID;
  final String userName;

  const AudioRoomPage({super.key, required this.roomID, required this.userID, required this.userName});

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<ZegoUIKitUser> _roomUsers = [];
  List<ChatMessage> _messages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeZego();
    _setupAnimations();
  }

  Future<void> _initializeZego() async {
    try {
      // IMPORTANT: Initialize ZegoUIKit with your App ID and App Sign
      // You need to replace these with your actual credentials from Zego Console
      await ZegoUIKit().init(
        appID: 1738777063,
        appSign: "1b5dbd4c4dac51d753a6a4eb7563490006a11a161c5133a4bb2f4727d5e34550",
        scenario: ZegoScenario.Default,
      );

      /// login user
      ZegoUIKit().login(widget.userID, widget.userName);

      /// join room
      await ZegoUIKit().joinRoom(widget.roomID);

      /// listen to users
      ZegoUIKit().getUserJoinStream().listen((users) {
        setState(() => _roomUsers.addAll(users));
      });
      ZegoUIKit().getUserLeaveStream().listen((users) {
        setState(() => _roomUsers.removeWhere((u) => users.map((e) => e.id).contains(u.id)));
      });

      /// listen to messages
      ZegoUIKit().getInRoomMessageStream().listen((m) {
        setState(() {
          _messages.add(ChatMessage(username: m.user.name, message: m.message, timestamp: DateTime.now()));
          _scrollToBottom();
        });
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing Zego: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize audio room: $e')),
        );
      }
    }
  }

  void _setupAnimations() {
    /// pulse animation
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _pulseController.dispose();

    ZegoUIKit().leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildStreamerProfile(),
                      const SizedBox(height: 20),
                      _buildSeatsGrid(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              _buildChatSection(),
              _buildChatInput(),
            ],
          )
              : const Center(
            child: CircularProgressIndicator(
              color: Colors.pink,
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- UI Parts ----------------

  Widget _buildAppBar() {
    bool isFollowing = true;
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 16, top: 16, bottom: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          // Profile Picture
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500]),
              boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipOval(
              child: Image.network(
                "",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, color: Colors.white, size: 28);
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name and ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(colors: [Colors.white, Colors.pink.shade200]).createShader(bounds),
                  child: Text(
                    "Name",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'ID: ${widget.roomID}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          // Follow Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isFollowing ? null : LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              border: Border.all(color: isFollowing ? Colors.grey.shade600 : Colors.transparent, width: 1),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamerProfile() {
    return Column(
      children: [
        Stack(
          children: [
            // --- Co-host empty chair on the right ---
            Positioned(
              top: 0,
              bottom: 0,
              child: Transform.translate(
                offset: const Offset(120, 0),
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.pink.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.event_seat, color: Colors.white, size: 28)),
                ),
              ),
            ),

            // --- Main host ---
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade300, Colors.pink.shade500, Colors.purple.shade400],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 8)),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.network(
                        "",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 60),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500]).createShader(bounds),
          child: Text(
            widget.userName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 110, mainAxisExtent: 100),
      itemCount: 12,
      itemBuilder: (context, index) {
        // Try to find user for this seat
        final users = ZegoUIKit().getAudioVideoList();
        final user = index < users.length ? users[index] : null;

        if (user != null) {
          return _buildCircularSeat(user);
        } else {
          return _buildEmptySeat(index + 1);
        }
      },
    );
  }

  Widget _buildEmptySeat(int seatNo) {
    return Padding(
      padding: const EdgeInsets.all(5),
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
            child: const Icon(Icons.event_seat, color: Colors.pink, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Seat $seatNo',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSeat(ZegoUIKitUser user) {
    return StreamBuilder<double>(
      stream: user.soundLevel,
      builder: (context, snapshot) {
        final level = snapshot.data ?? 0.0;
        final bool isSpeaking = level > 30;

        return Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking ? Colors.green : Colors.pink.withOpacity(0.4),
                    width: isSpeaking ? 3 : 2,
                  ),
                ),
                child: ClipOval(
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name.characters.first : "?",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withOpacity(0.3)),
      child: _messages.isEmpty
          ? Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      )
          : ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final m = _messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  "${m.username}: ",
                  style: TextStyle(color: Colors.pink.shade300, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    m.message,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.pink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              if (_chatController.text.trim().isNotEmpty) {
                final messageText = _chatController.text.trim();
                try {
                  await ZegoUIKit().sendInRoomMessage(messageText);

                  // Manually add your own message to the chat list
                  setState(() {
                    _messages.add(ChatMessage(
                      username: widget.userName,
                      message: messageText,
                      timestamp: DateTime.now(),
                    ));
                  });

                  _chatController.clear();
                  _scrollToBottom();
                } catch (e) {
                  print('Error sending message: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send message: $e')),
                    );
                  }
                }
              }
            },
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
}

/// Local message model
class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.username, required this.message, required this.timestamp});
}

class MicButton extends StatefulWidget {
  final String userID;

  const MicButton({super.key, required this.userID});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool isMicOn = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
      onPressed: () {
        setState(() {
          isMicOn = !isMicOn;
        });
        ZegoUIKit().turnMicrophoneOn(isMicOn);
      },
    );
  }
}