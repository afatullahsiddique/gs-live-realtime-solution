import 'package:cute_live/ui/home/home_page.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PKTab extends StatelessWidget {
  final List<StreamerModel> streamers;

  const PKTab({required this.streamers, super.key});

  @override
  Widget build(BuildContext context) {
    // Group streamers into pairs
    List<List<StreamerModel>> streamerPairs = [];
    for (int i = 0; i < streamers.length - 1; i += 2) {
      streamerPairs.add([streamers[i], streamers[i + 1]]);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      itemCount: streamerPairs.length,
      itemBuilder: (context, index) {
        final pair = streamerPairs[index];
        final streamer1 = pair[0];
        final streamer2 = pair[1];
        final isTopMatch = index < 3; // Top 3 matches get special treatment

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildVSCard(streamer1, streamer2, isTopMatch, index),
        );
      },
    );
  }

  Widget _buildVSCard(StreamerModel streamer1, StreamerModel streamer2, bool isTopMatch, int index) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTopMatch
              ? [
                  const Color(0xFF1a0a0a),
                  const Color(0xFF2d1b2b),
                  const Color(0xFF4a2c4a),
                  const Color(0xFFff6b9d).withOpacity(0.3),
                ]
              : [const Color(0xFF0a0a0a), const Color(0xFF1a1a1a), const Color(0xFF2a1a2a)],
        ),
        boxShadow: [
          BoxShadow(
            color: isTopMatch ? Colors.pink.withOpacity(0.3) : Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background effects for top matches
          if (isTopMatch) _buildAnimatedBackground(index),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left streamer
                Expanded(child: _buildStreamerSide(streamer1, true, isTopMatch)),

                // VS section
                _buildVSSection(streamer1, streamer2, isTopMatch),

                // Right streamer
                Expanded(child: _buildStreamerSide(streamer2, false, isTopMatch)),
              ],
            ),
          ),

          // Top match indicator
          if (isTopMatch) _buildTopMatchIndicator(index),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(int index) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Pulsing effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.withOpacity(0.5), width: 2),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.pink.withOpacity(0.1), Colors.transparent, Colors.purple.withOpacity(0.1)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMatchIndicator(int index) {
    final ranks = ['🥇', '🥈', '🥉'];
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.yellow.shade600, Colors.orange.shade600]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.yellow.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ranks[index], style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              const Text(
                'TOP MATCH',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamerSide(StreamerModel streamer, bool isLeft, bool isTopMatch) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Profile image with power indicator
        Stack(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isTopMatch
                      ? [Colors.pink.shade300, Colors.purple.shade400]
                      : [Colors.grey.shade600, Colors.grey.shade800],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isTopMatch ? Colors.pink.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.network(
                  streamer.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
                      child: Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 35),
                    );
                  },
                ),
              ),
            ),
            // Power level indicator
            Positioned(
              bottom: 0,
              right: isLeft ? 0 : null,
              left: isLeft ? null : 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${(streamer.viewCount / 100).round()}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Streamer name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isTopMatch ? Colors.pink.withOpacity(0.5) : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            streamer.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isLeft ? TextAlign.start : TextAlign.end,
          ),
        ),

        const SizedBox(height: 6),

        // View count with battle power
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600.withOpacity(0.8), Colors.blue.shade800.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, size: 12, color: Colors.yellow.shade300),
              const SizedBox(width: 2),
              Text(
                '${streamer.viewCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVSSection(StreamerModel streamer1, StreamerModel streamer2, bool isTopMatch) {
    final total = streamer1.viewCount + streamer2.viewCount;
    final streamer1Percentage = total > 0 ? (streamer1.viewCount / total) : 0.5;

    return Container(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // VS Text with glow effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTopMatch
                    ? [Colors.red.shade500, Colors.red.shade700]
                    : [Colors.grey.shade600, Colors.grey.shade800],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: isTopMatch ? Colors.red.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black)],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Battle power indicator
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.black.withOpacity(0.3)),
            child: Stack(
              children: [
                // Streamer 1 power
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 60 * streamer1Percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                    ),
                  ),
                ),
                // Streamer 2 power
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 60 * (1 - streamer1Percentage),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Battle status
          Text(
            'BATTLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTopMatch ? Colors.pink.shade300 : Colors.white.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
