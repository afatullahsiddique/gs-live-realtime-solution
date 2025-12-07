import 'package:flutter/material.dart';
import '../../../../data/remote/firebase/assets_services.dart';
import '../../../../data/remote/firebase/room_services.dart';

class EmojiBottomSheet extends StatelessWidget {
  final String roomId;

  const EmojiBottomSheet({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.5;

    return SafeArea(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFF2d1b2b),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Send Emoji',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const TabBar(
                indicatorColor: Colors.pink,
                labelColor: Colors.pink,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Emoji'),
                  Tab(text: 'Text Emoji'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StreamBuilder<List<EmojiModel>>(
                      stream: AssetsService.getEmojis(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.pink));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                          );
                        }

                        final emojis = snapshot.data ?? [];

                        if (emojis.isEmpty) {
                          return const Center(
                            child: Text('No emojis found.', style: TextStyle(color: Colors.white70)),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = emojis[index];
                            return GestureDetector(
                              onTap: () async {
                                try {
                                  await RoomService.sendEmoji(roomId, emoji.imageUrl, emoji.name);
                                  Navigator.pop(context);
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: Image.network(
                                emoji.imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.pink.withOpacity(0.5),
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Center(
                      child: Text('Text emojis coming soon!', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showEmojiBottomSheet(BuildContext context, String roomId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EmojiBottomSheet(roomId: roomId),
  );
}
