import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class StatusPage extends StatefulWidget {
  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  final TextEditingController _postController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Pure black
              Color(0xFF1a0a0a), // Dark black
              Color(0xFF2d1b2b), // Dark purple-black
              Color(0xFF4a2c4a), // Medium purple
              Color(0xFFff6b9d), // Pink accent
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: EdgeInsets.only(left: 0, right: 20, top: 0, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 2))],
                      ),
                    ),
                    Spacer()
                  ],
                ),
              ),

              // Fixed Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Row(
                      children: [
                        _buildTabItem('Hot', 0, Icons.whatshot),
                        _buildTabItem('New', 1, Icons.fiber_new),
                        _buildTabItem('Followed', 2, Icons.favorite),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      // Post Input Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: TextField(
                              controller: _postController,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "What's on your mind?",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                prefixIcon: Container(
                                  margin: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade600]),
                                    border: Border.all(color: Colors.pink.withOpacity(0.3), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage('https://picsum.photos/100/100?random=user'),
                                  ),
                                ),
                                suffixIcon: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: IconButton(
                                        icon: Icon(Icons.send, color: Colors.pink.shade300),
                                        onPressed: () {
                                          // Handle post submission
                                        },
                                      ),
                                    );
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Posts List
                      ...List.generate(10, (index) => _buildPostCard(index)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon) {
    bool isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.all(2),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected ? LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade600]) : null,
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 0))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), size: 18),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(int index) {
    List<String?> sampleImages = [
      'https://picsum.photos/400/300?random=$index',
      null, // Text only post
      'https://picsum.photos/400/250?random=${index + 10}',
    ];

    String? imageUrl = sampleImages[index % sampleImages.length];
    bool hasImage = imageUrl != null;

    List<String> captions = [
      "Just finished an amazing live stream! Thanks to everyone who joined 💕",
      "Feeling grateful for all the love and support from my fans! You make every day special ✨",
      "New outfit for tonight's stream! What do you think? 🎀",
      "Behind the scenes prep time! Getting ready to go live soon 🎬",
      "Thank you for the amazing gifts tonight! You're all so sweet 💝",
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade600]),
                        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 2),
                      ),
                      padding: EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage('https://picsum.photos/100/100?random=${index + 50}'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CutieStreamer${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${2 + index} hours ago',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.pink.shade400]),
                      ),
                      child: Text(
                        'VIP',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Caption
                Text(
                  captions[index % captions.length],
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.4),
                ),

                if (hasImage) ...[
                  SizedBox(height: 12),
                  // Image/Video Content
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
                        if (index % 3 == 1) // Some posts are videos
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                    border: Border.all(color: Colors.pink.withOpacity(0.6), width: 2),
                                  ),
                                  child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    _buildActionButton(Icons.favorite_border, '${156 + (index * 23)}', Colors.pink.shade300),
                    SizedBox(width: 24),
                    _buildActionButton(Icons.chat_bubble_outline, '${23 + (index * 7)}', Colors.white.withOpacity(0.7)),
                    SizedBox(width: 24),
                    _buildActionButton(Icons.share_outlined, '${12 + (index * 3)}', Colors.white.withOpacity(0.7)),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(Icons.bookmark_border, color: Colors.white.withOpacity(0.7), size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
