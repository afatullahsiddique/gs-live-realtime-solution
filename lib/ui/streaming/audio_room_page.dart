import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class AudioRoomPage extends StatefulWidget {
  const AudioRoomPage({super.key});

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Dummy data
  final StreamerModel _streamer = StreamerModel(
    name: 'Luna Park',
    id: '987654321',
    profileImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    diamonds: 15420,
    stars: 8750,
    isFollowing: false,
  );

  final List<SeatModel> _seats = [
    SeatModel(
      id: 1,
      user: UserModel(name: 'Alex', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'),
      isSpeaking: true,
    ),
    SeatModel(id: 2, user: null),
    SeatModel(
      id: 3,
      user: UserModel(name: 'Emma', avatar: 'https://images.unsplash.com/photo-1494790108755-2616b332c5cd?w=200'),
      isSpeaking: false,
    ),
    SeatModel(id: 4, user: null),

    SeatModel(id: 5, user: null),
    SeatModel(
      id: 6,
      user: UserModel(name: 'Sophie', avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200'),
      isSpeaking: false,
    ),
    SeatModel(id: 7, user: null),
    SeatModel(
      id: 8,
      user: UserModel(name: 'Jake', avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200'),
      isSpeaking: true,
    ),
    SeatModel(
      id: 9,
      user: UserModel(name: 'Ryan', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'),
      isSpeaking: true,
    ),
    SeatModel(id: 10, user: null),
    SeatModel(id: 11, user: null),
    SeatModel(id: 12, user: null),
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(
      username: 'Emma Rose',
      message: 'Great session! 🎵',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    ChatMessage(
      username: 'Alex Chen',
      message: 'Love this song!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      username: 'Sophie Kim',
      message: 'Can you play more jazz?',
      timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    ChatMessage(
      username: 'Jake Wilson',
      message: '🔥🔥🔥',
      timestamp: DateTime.now().subtract(const Duration(seconds: 15)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _pulseController.dispose();
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
          child: Column(
            children: [
              _buildAppBar(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // _buildAchievementChips(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                _streamer.profileImage,
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
                    _streamer.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'ID: ${_streamer.id}',
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
              gradient: _streamer.isFollowing
                  ? null
                  : LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              color: _streamer.isFollowing ? Colors.grey.shade700 : null,
              border: Border.all(color: _streamer.isFollowing ? Colors.grey.shade600 : Colors.transparent, width: 1),
            ),
            child: Text(
              _streamer.isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildAchievementChip(
            icon: Icons.diamond_rounded,
            count: _streamer.diamonds,
            color: Colors.cyan,
            label: 'Diamonds',
          ),
          const SizedBox(width: 12),
          _buildAchievementChip(icon: Icons.star_rounded, count: _streamer.stars, color: Colors.amber, label: 'Stars'),
        ],
      ),
    );
  }

  Widget _buildAchievementChip({
    required IconData icon,
    required int count,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            _formatNumber(count),
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamerProfile() {
    return Column(
      children: [
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
                    _streamer.profileImage,
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
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500]).createShader(bounds),
          child: Text(
            _streamer.name,
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
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(mainAxisExtent: 100, maxCrossAxisExtent: 110),
      itemCount: _seats.length,
      itemBuilder: (context, index) {
        return _buildCircularSeat(_seats[index]);
      },
    );
  }

  // The individual seat widget, now a compact circle
  Widget _buildCircularSeat(SeatModel seat) {
    final bool isEmpty = seat.user == null;

    return GestureDetector(
      onTap: () {
        // Handle seat tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5), // Adjust spacing between circles
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55, // Sized for a circular shape
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.black.withOpacity(0.3), Colors.pink.withOpacity(0.1)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.pink.shade800.withOpacity(0.3), Colors.purple.shade800.withOpacity(0.3)],
                      ),
                border: Border.all(
                  color: isEmpty
                      ? Colors.pink.withOpacity(0.2)
                      : seat.isSpeaking
                      ? Colors.green.shade400
                      : Colors.pink.withOpacity(0.4),
                  width: seat.isSpeaking ? 3 : 2,
                ),
                boxShadow: [
                  if (seat.isSpeaking)
                    BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10)
                  else if (!isEmpty)
                    BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: ClipOval(
                child: isEmpty
                    ? Icon(Icons.event_seat, color: Colors.pink.shade300, size: 28)
                    : Image.network(
                        seat.user!.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700]),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
            if (!isEmpty)
              SizedBox(
                width: 60,
                child: Text(
                  seat.user!.name,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              '${seat.id}',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.pink.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${message.username}: ',
                      style: TextStyle(color: Colors.pink.shade300, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Text(
                        message.message,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
              boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (_chatController.text.trim().isNotEmpty) {
                  // Send message logic
                  _chatController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

// Data Models
class StreamerModel {
  final String name;
  final String id;
  final String profileImage;
  final int diamonds;
  final int stars;
  final bool isFollowing;

  StreamerModel({
    required this.name,
    required this.id,
    required this.profileImage,
    required this.diamonds,
    required this.stars,
    required this.isFollowing,
  });
}

class SeatModel {
  final int id;
  final UserModel? user;
  final bool isSpeaking;

  SeatModel({required this.id, this.user, this.isSpeaking = false});
}

class UserModel {
  final String name;
  final String avatar;

  UserModel({required this.name, required this.avatar});
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.username, required this.message, required this.timestamp});
}
