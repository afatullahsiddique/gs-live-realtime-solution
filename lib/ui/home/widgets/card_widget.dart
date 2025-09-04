import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/view_count.dart';
import '../../../navigation/routes.dart';
import '../home_page.dart';
import 'live_animation.dart';

class AnimatedStreamerCard extends StatefulWidget {
  final StreamerModel streamer;

  const AnimatedStreamerCard({Key? key, required this.streamer}) : super(key: key);

  @override
  _AnimatedStreamerCardState createState() => _AnimatedStreamerCardState();
}

class _AnimatedStreamerCardState extends State<AnimatedStreamerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller to drive the gradient animation
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true); // This makes the animation repeat and reverse
  }

  @override
  void dispose() {
    _controller.dispose(); // Important: Dispose of the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.streamer.isVideo) {
          context.push(Routes.audioRoom.path);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            if (widget.streamer.isPremium) BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 0)),
          ],
        ),
        // Use AnimatedBuilder to rebuild just the glowing part
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Animate the gradient's begin and end alignments
            final double value = _controller.value;
            final Alignment begin = Alignment(-1.0 + 2 * value, -1.0);
            final Alignment end = Alignment(1.0 - 2 * value, 1.0);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.streamer.isPremium
                    ? LinearGradient(
                        begin: begin,
                        end: end,
                        colors: [Colors.pink.shade300, Colors.purple.shade400, Colors.pink.shade500, Colors.orange.shade400],
                      )
                    : null,
              ),
              child: Padding(
                padding: widget.streamer.isPremium ? const EdgeInsets.all(3.0) : EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.network(
                        widget.streamer.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.grey.shade800, Colors.grey.shade900],
                              ),
                            ),
                            child: const Center(child: Icon(Icons.person, color: Colors.white54, size: 50)),
                          );
                        },
                      ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // View Count
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.streamer.isVideo ? Icons.videocam : Icons.mic,
                                            color: Colors.pink.shade300,
                                            size: widget.streamer.isVideo ? 14 : 16,
                                          ),
                                          // const SizedBox(width: 4),
                                          // Icon(Icons.visibility_rounded, color: Colors.grey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatViewCount(widget.streamer.viewCount),
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.purple.shade400]),
                                  ),
                                  child: const LiveWaveWidget(), // Replace Text with your custom widget
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Name
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                                  ),
                                  child: Text(
                                    widget.streamer.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
