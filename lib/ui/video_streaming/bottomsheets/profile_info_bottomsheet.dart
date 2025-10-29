import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import '../../../data/remote/firebase/profile_services.dart';
import 'follow_list_bottomsheet.dart';
import 'host_actions_bottomsheet.dart'; // Import new sheet
import 'report_user_bottomsheet.dart'; // Import new sheet

/// A bottom sheet that displays detailed info about a user.
class ProfileInfoBottomSheet extends StatelessWidget {
  final String userId;
  final String hostId; // The host of the *current* room
  final String roomId; // --- ADDED: Required for host actions ---

  const ProfileInfoBottomSheet({
    super.key,
    required this.userId,
    required this.hostId,
    required this.roomId, // --- ADDED ---
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isHost = userId == hostId;
    final bool isCurrentUser = userId == currentUserId;

    // --- NEW LOGIC ---
    final bool isCurrentUserTheHost = currentUserId == hostId;

    return StreamBuilder<DocumentSnapshot>(
      stream: ProfileService.getUserProfileStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator(color: Colors.pink));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String userName = data['displayName'] ?? 'Unknown User';
        final String? userPicture = data['photoUrl'];
        final int followerCount = data['followerCount'] ?? 0;
        final int followingCount = data['followingCount'] ?? 0;
        final int level = data['level'] ?? 1;

        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 250,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SVGAEasyPlayer(assetsName: "assets/svga/profile.svga", fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHost ? '@Host' : '@User',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        // --- MODIFIED HEADER LOGIC ---
                        if (!isCurrentUser) ...[
                          // I am the HOST viewing another user
                          if (isCurrentUserTheHost)
                            IconButton(
                              icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close this sheet
                                showHostActionsBottomSheet(
                                  context,
                                  targetUserId: userId,
                                  targetUserName: userName,
                                  roomId: roomId,
                                );
                              },
                            )
                          // I am a USER viewing another user
                          else
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close this sheet
                                showReportUserBottomSheet(context, reportedUserId: userId, reportedUserName: userName);
                              },
                              child: const Text(
                                'Report',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ]
                        // --- END MODIFIED LOGIC ---
                      ],
                    ),
                    // --- Profile Picture ---
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userPicture != null && userPicture.isNotEmpty ? NetworkImage(userPicture) : null,
                      child: (userPicture == null || userPicture.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),

                    const SizedBox(height: 12),
                    // --- User Info ---
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.shade700, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Lv $level",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // --- Stats Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Followers
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Close this sheet
                            showFollowListBottomSheet(context, userId: userId, listType: FollowListType.followers);
                          },
                          child: Column(
                            children: [
                              Text(
                                followerCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text('Followers', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        // Divider
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        // Followings
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Close this sheet
                            showFollowListBottomSheet(context, userId: userId, listType: FollowListType.following);
                          },
                          child: Column(
                            children: [
                              Text(
                                followingCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text('Following', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Follow | Message Button Row ---
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            // Follow/Following Button
                            Expanded(
                              child: StreamBuilder<bool>(
                                stream: ProfileService.isFollowing(userId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return ElevatedButton(onPressed: null, child: const Text('...'));
                                  }
                                  final bool isFollowing = snapshot.data ?? false;

                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing ? Colors.grey.shade800 : Colors.pink,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        if (isFollowing) {
                                          await ProfileService.unfollowUser(userId);
                                        } else {
                                          await ProfileService.followUser(userId);
                                        }
                                      } catch (e) {
                                        debugPrint('Error following/unfollowing user: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      }
                                    },
                                    child: Text(isFollowing ? 'Following' : 'Follow'),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Message Button
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  // TODO: Implement navigation to chat page
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Message functionality not implemented yet.')),
                                  );
                                },
                                child: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Add bottom padding if the buttons are visible
                    if (!isCurrentUser) const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Top-level function to show the profile info bottom sheet.
void showProfileInfoBottomSheet(
    BuildContext context, {
      required String userId,
      required String hostId,
      required String roomId, // --- ADDED ---
    }) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d1b2b),
    isScrollControlled: true,
    builder: (context) {
      return ProfileInfoBottomSheet(
        userId: userId,
        hostId: hostId,
        roomId: roomId, // --- ADDED ---
      );
    },
  );
}