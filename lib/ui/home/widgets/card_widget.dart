import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/view_count.dart';
import '../../../navigation/routes.dart';
import '../home_page.dart';
import 'live_animation.dart';

class AnimatedStreamerCard extends StatefulWidget {
  final StreamerModel streamer;
  final int? index;

  const AnimatedStreamerCard({Key? key, required this.streamer, this.index}) : super(key: key);

  @override
  _AnimatedStreamerCardState createState() => _AnimatedStreamerCardState();
}

class _AnimatedStreamerCardState extends State<AnimatedStreamerCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.streamer.isVideo) {
          context.push(
            Routes.audioRoom.path,
            extra: {
              "roomId": widget.streamer.id,
              "name": FirebaseAuth.instance.currentUser?.displayName ?? "Unknown",
              "isHost": false,
            },
          );
        } else {
          context.push(Routes.videoRoom.path, extra: {"roomId": widget.streamer.id, "isHost": false});
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: widget.streamer.isPremium ? const EdgeInsets.all(3.0) : EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.streamer.isPremium ? 4 : 14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.network(
                        widget.streamer.imageUrl ?? "",
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

                      if (widget.index == 0)
                        Positioned.fill(
                          child: SVGAEasyPlayer(assetsName: "assets/svga/room_cover_1.svga", fit: BoxFit.cover),
                        ),
                      if (widget.index == 1)
                        Positioned.fill(child: SVGAEasyPlayer(assetsName: "assets/svga/room_cover_2.svga")),

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
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (widget.streamer.isLocked)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.lock, color: Colors.white, size: 18),
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
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                                ),
                                child: Text(
                                  widget.streamer.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ],
      ),
    );
  }
}
