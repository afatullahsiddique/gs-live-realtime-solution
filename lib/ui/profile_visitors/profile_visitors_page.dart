import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileVisitorsPage extends StatelessWidget {
  const ProfileVisitorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final visitors = [
      {"name": "Alice Johnson", "time": "2 minutes ago"},
      {"name": "Michael Smith", "time": "10 minutes ago"},
      {"name": "Sophia Williams", "time": "1 hour ago"},
      {"name": "James Brown", "time": "Yesterday"},
      {"name": "Emma Davis", "time": "2 days ago"},
    ];

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
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 20, top: 0, bottom: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.pink),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text(
                      "Profile Visitors",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Visitors List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.pinkAccent.withOpacity(0.3),
                            child: Text(visitor["name"]![0], style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visitor["name"]!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Visited ${visitor["time"]}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
