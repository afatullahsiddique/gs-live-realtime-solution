import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

/// A data model for the UI to display a top earner.
class DisplayEarner {
  final String name;
  final String pictureUrl;
  final int earnings;

  DisplayEarner({required this.name, required this.pictureUrl, required this.earnings});
}

/// A bottom sheet that displays the round results and auto-closes after 5 seconds.
class GameResultBottomSheet extends StatefulWidget {
  final String roundId;
  final int winningIndex;
  final String resultImagePath;
  final int totalEarnings;
  final int totalBets;
  final List<DisplayEarner> topEarners; // <-- UPDATED Type

  const GameResultBottomSheet({
    super.key,
    required this.roundId,
    required this.winningIndex,
    required this.resultImagePath,
    required this.totalEarnings,
    required this.totalBets,
    required this.topEarners, // <-- UPDATED
  });

  @override
  State<GameResultBottomSheet> createState() => _GameResultBottomSheetState();
}

class _GameResultBottomSheetState extends State<GameResultBottomSheet> {
  Timer? _timer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // ... (initState, _startTimer, dispose, _formatCurrency methods are unchanged)

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          Navigator.pop(context); // Auto-close the sheet
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    return NumberFormat.decimalPattern().format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500);
    final highlightStyle = const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: BoxDecoration(
          color: const Color(0xFF2a1a4f), // A dark purple, matches theme
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.pink, width: 2),
        ),
        child: Stack(
          children: [
            // --- MODIFICATION HERE ---
            // Wrap the Column in a SizedBox to force it to expand
            SizedBox(
              width: double.infinity, // <-- This forces it to take full width
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // This still centers the content
                children: [
                  // --- Round Result and Icon ---
                  Text(
                    'Round ${widget.roundId} Result:',
                    style: textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Image.asset(widget.resultImagePath, height: 60, width: 60),
                  const SizedBox(height: 16),

                  // --- Earnings ---
                  RichText(
                    text: TextSpan(
                      text: 'This round earnings: ',
                      style: textStyle,
                      children: [
                        TextSpan(
                          text: _formatCurrency(widget.totalEarnings),
                          style: highlightStyle.copyWith(color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Bets ---
                  RichText(
                    text: TextSpan(
                      text: 'This round bets: ',
                      style: textStyle,
                      children: [
                        TextSpan(
                          text: _formatCurrency(widget.totalBets),
                          style: highlightStyle.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Ranking Section ---
                  const Text(
                    'This Round Ranking',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // --- Top 3 Row ---
                  _buildTopEarnersRow(),
                ],
              ),
            ),
            // --- END MODIFICATION ---

            // --- Timer in Top-Right Corner ---
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_secondsRemaining s',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED: This widget now builds from List<DisplayEarner> ---
  Widget _buildTopEarnersRow() {
    if (widget.topEarners.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "No one won this round.",
          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.topEarners.map((earner) {
        return Flexible(
          child: _buildTopEarnerProfile(pictureUrl: earner.pictureUrl, name: earner.name, amount: earner.earnings),
        );
      }).toList(),
    );
  }

  // --- UPDATED: Helper widget to build one profile ---
  Widget _buildTopEarnerProfile({required String pictureUrl, required String name, required int amount}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.pinkLight,
          backgroundImage: NetworkImage(pictureUrl),
          onBackgroundImageError: (e, s) => const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
