import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/view_count.dart';
import '../../../core/widgets/auto_scroll_text.dart';
import '../../../navigation/routes.dart';
import '../home_page.dart';
class AnimatedStreamerCard extends StatefulWidget {
  final StreamerModel streamer;
  final String? animationFilePath;

  const AnimatedStreamerCard({super.key, required this.streamer, this.animationFilePath});

  @override
  State<AnimatedStreamerCard> createState() => _AnimatedStreamerCardState();
}

class _AnimatedStreamerCardState extends State<AnimatedStreamerCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(Routes.partyRoom.path, extra: {"roomId": widget.streamer.id, "isHost": false});
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

                      // --- 2. UPDATE ANIMATION LOGIC ---
                      // If a file path is provided, play the animation based on its type
                      if (widget.animationFilePath != null)
                        if (widget.animationFilePath!.endsWith('.svga'))
                          Positioned.fill(
                            child: SVGAEasyPlayer(
                              assetsName: widget.animationFilePath!,
                              fit: BoxFit.cover, // Apply fit: BoxFit.cover consistently
                            ),
                          )
                        else if (widget.animationFilePath!.endsWith('.webp')) // Assuming .webp
                          Positioned.fill(child: Image.asset(widget.animationFilePath!, fit: BoxFit.cover)),
                      // --- END OF CHANGE ---

                      // Branded Floating LIVE Icons
                      if (widget.streamer.isVideo || widget.streamer.isLiveStream)
                        Positioned(
                          right: 4,
                          top: MediaQuery.of(context).size.height * 0.1,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle blur shadow for the "floating" feel
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                widget.streamer.id.length % 2 == 0 
                                  ? 'assets/images/gf_live.png' 
                                  : 'assets/images/gs_live.jpeg',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            ],
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
                                        color: Colors.black.withValues(alpha: 0.6),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.streamer.isVideo ? Icons.videocam : Icons.mic,
                                            color: Colors.pink.shade300,
                                            size: widget.streamer.isVideo ? 14 : 16,
                                          ),
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
                                const SizedBox(width: 8),
                                if (widget.streamer.isLocked)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.lock, color: Colors.white, size: 18),
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
                                  color: Colors.black.withValues(alpha: 0.3),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                                ),
                                child: AutoScrollText(
                                  text: widget.streamer.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
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
