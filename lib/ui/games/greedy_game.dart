import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class _LeafItemConfig {
  final String assetPath;
  final double sizeFactor;
  final double radiusFactor;
  final double angleDegrees;
  final int multiplier;

  _LeafItemConfig({
    required this.assetPath,
    required this.sizeFactor,
    required this.radiusFactor,
    required this.angleDegrees,
    required this.multiplier,
  });
}

class _CenterItemConfig {
  final String assetPath;
  final double sizeFactor;
  final double offsetXFactor;
  final double offsetYFactor;

  _CenterItemConfig({
    required this.assetPath,
    required this.sizeFactor,
    this.offsetXFactor = 0.0,
    this.offsetYFactor = 0.0,
  });
}

class GreedyGamePage extends StatefulWidget {
  const GreedyGamePage({super.key});

  @override
  State<GreedyGamePage> createState() => _GreedyGamePageState();
}

class _GreedyGamePageState extends State<GreedyGamePage> {
  final String boardBackgroundImage = 'assets/greedy/board.png';

  // --- Game Timers ---
  final Duration _totalSpinDuration = const Duration(seconds: 3);
  final Duration _leafHighlightDuration = const Duration(milliseconds: 400);
  final Duration _bettingTimeDuration = const Duration(seconds: 25);
  final Duration _bettingResultDuration = const Duration(seconds: 4);

  // --- Game State ---
  bool _isSpinning = false;
  bool _isBettingTime = true;
  int _currentLeafIndex = 0;
  int? _spinResultIndex;
  Timer? _spinTimer;
  Timer? _bettingTimer;
  int _roundNumber = 1;
  int _countdownSeconds = 15;

  // --- Player & Bet State ---
  int _balance = 1000000;
  int _todaysRevenue = 0;
  int _selectedCoinValue = 0;

  /// Stores the history of winning images for the session
  final List<String> _winningResultsHistory = [];

  /// Stores the bets for the current round.
  /// Key: Leaf index (0-7), Value: Total bet amount
  final Map<int, int> _bets = {};

  // --- Asset Lists ---
  final Map<String, int> _coinValues = {
    'assets/greedy/coin_500.png': 500,
    'assets/greedy/coin_1k.png': 1000,
    'assets/greedy/coin_10k.png': 10000,
    'assets/greedy/coin_50k.png': 50000,
  };

  final List<String> _resultImages = [
    'assets/greedy/burger_result.png',
    'assets/greedy/chicken_result.png',
    'assets/greedy/cauliflower_result.png',
    'assets/greedy/corn_result.png',
    'assets/greedy/fish_result.png',
    'assets/greedy/grapes_result.png',
    'assets/greedy/octopus_result.png',
    'assets/greedy/strawberry_result.png',
  ];

  final String _saladImagePath = 'assets/greedy/salad.png';
  final String _pizzaImagePath = 'assets/greedy/pizza.png';

  final _CenterItemConfig _centerConfig = _CenterItemConfig(
    assetPath: 'assets/greedy/greedy_icon.png',
    sizeFactor: 0.325,
    offsetXFactor: 0.0011,
    offsetYFactor: -0.005,
  );

  // (Your _leafConfigs method remains the same)
  List<_LeafItemConfig> _leafConfigs() => [
    _LeafItemConfig(
      assetPath: 'assets/greedy/burger.png',
      sizeFactor: 0.19,
      radiusFactor: 0.375,
      angleDegrees: -89.5,
      multiplier: 10,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/chicken.png',
      sizeFactor: 0.19,
      radiusFactor: 0.388,
      angleDegrees: -45,
      multiplier: 45,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/cauliflower.png',
      sizeFactor: 0.19,
      radiusFactor: 0.383,
      angleDegrees: -0.15,
      multiplier: 5,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/corn.png',
      sizeFactor: 0.19,
      radiusFactor: 0.38,
      angleDegrees: 44.2,
      multiplier: 5,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/fish.png',
      sizeFactor: 0.19,
      radiusFactor: 0.37,
      angleDegrees: 90,
      multiplier: 15,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/grapes.png',
      sizeFactor: 0.19,
      radiusFactor: 0.38,
      angleDegrees: 135.7,
      multiplier: 5,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/octopus.png',
      sizeFactor: 0.19,
      radiusFactor: 0.38,
      angleDegrees: 181,
      multiplier: 25,
    ),
    _LeafItemConfig(
      assetPath: 'assets/greedy/strawberry.png',
      sizeFactor: 0.19,
      radiusFactor: 0.387,
      angleDegrees: -134.5,
      multiplier: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startBettingPhase();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _bettingTimer?.cancel();
    super.dispose();
  }

  /// Formats a number as a compact string (e.g., 12345 -> "12,345")
  String _formatCurrency(int amount) {
    return NumberFormat.decimalPattern().format(amount);
  }

  /// Formats a number as a compact string (e.g., 12345 -> "12.3k")
  String _formatBetAmount(int amount) {
    if (amount >= 1000000) {
      double value = amount / 1000000.0;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}m';
    }
    if (amount >= 1000) {
      double value = amount / 1000.0;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}k';
    }
    return amount.toString();
  }

  /// Starts the 10-second betting countdown
  void _startBettingPhase() {
    setState(() {
      _isBettingTime = true;
      _isSpinning = false;
      _spinResultIndex = null;
      _bets.clear();
      _countdownSeconds = _bettingTimeDuration.inSeconds;
    });

    _bettingTimer?.cancel();
    _bettingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isBettingTime = false;
        });
        _startSpin();
      }
    });
  }

  /// Places a bet on a specific leaf
  void _onBet(int leafIndex) {
    if (!_isBettingTime) {
      _showToast("Betting time is over!", isError: true);
      return;
    }
    if (_selectedCoinValue == 0) {
      _showToast("Please select a coin to bet with.", isError: true);
      return;
    }
    if (_balance < _selectedCoinValue) {
      _showToast("Not enough balance!", isError: true);
      return;
    }

    setState(() {
      _balance -= _selectedCoinValue;
      // Add the selected coin value to any existing bet on this leaf
      _bets[leafIndex] = (_bets[leafIndex] ?? 0) + _selectedCoinValue;
    });
  }

  /// Removes a bet from a specific leaf
  void _onRemoveBet(int leafIndex) {
    if (!_isBettingTime) {
      _showToast("Betting time is over!", isError: true);
      return;
    }

    final int currentBet = _bets[leafIndex] ?? 0;
    if (currentBet == 0) {
      // No bet to remove
      return;
    }

    setState(() {
      // Add the bet amount back to the balance
      _balance += currentBet;
      // Remove the bet from the map
      _bets.remove(leafIndex);
    });
  }

  /// Starts the spinning animation
  void _startSpin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _spinResultIndex = null;
      _currentLeafIndex = math.Random().nextInt(8); // Start from a random pos
    });

    final startTime = DateTime.now();
    final totalLeaves = _leafConfigs().length;

    // Pre-calculate the final winning index
    // This is a simple (and predictable) way to "choose" a winner.
    // For a real game, you'd get this result from a server.
    final winningIndex = math.Random().nextInt(totalLeaves);

    // Calculate total ticks needed
    final int minSpins = 3 * totalLeaves; // At least 3 full spins
    final int ticksToWinner = (totalLeaves - _currentLeafIndex + winningIndex) % totalLeaves;
    final int totalTicks = minSpins + ticksToWinner;

    final Duration tickDuration = _totalSpinDuration ~/ totalTicks;

    _spinTimer = Timer.periodic(tickDuration, (timer) {
      final elapsedTime = DateTime.now().difference(startTime);

      if (elapsedTime >= _totalSpinDuration) {
        timer.cancel();
        // Ensure the final index is the one we chose
        _currentLeafIndex = winningIndex;
        _processSpinResult(winningIndex);
      } else {
        setState(() {
          _currentLeafIndex = (_currentLeafIndex + 1) % totalLeaves;
        });
      }
    });
  }

  /// Processes the result after the spin animation completes
  void _processSpinResult(int winningIndex) {
    final winningConfig = _leafConfigs()[winningIndex];
    final int? playerBetOnWinner = _bets[winningIndex];

    int winnings = 0;
    String toastMessage = '';
    bool didPlaceAnyBet = _bets.isNotEmpty;

    if (playerBetOnWinner != null && playerBetOnWinner > 0) {
      // Player won!
      winnings = playerBetOnWinner * winningConfig.multiplier;
      toastMessage = 'You won ${_formatCurrency(winnings)}! (${winningConfig.multiplier}x)';

      setState(() {
        _balance += winnings;
        _todaysRevenue += winnings;

        if (winningIndex < _resultImages.length) {
          _winningResultsHistory.add(_resultImages[winningIndex]);
        }
      });
    } else if (didPlaceAnyBet) {
      // Player lost, but they did place a bet
      toastMessage = 'No win this round. Try again!';
    }
    // If didPlaceAnyBet is false and they didn't win, toastMessage remains empty

    setState(() {
      _isSpinning = false;
      _spinResultIndex = winningIndex;
      _roundNumber = _roundNumber + 1;
    });

    if (toastMessage.isNotEmpty) {
      _showToast(toastMessage, isError: winnings == 0);
    }

    // Wait for sometime to show the result, then start the next round
    Future.delayed(_bettingResultDuration, () {
      if (mounted) {
        _startBettingPhase();
      }
    });
  }

  /// Helper to show a SnackBar
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.amber[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Greedy Game',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Round: $_roundNumber',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenShortestSide = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;

                    final double boardSize = screenShortestSide * 1;
                    return _buildGameWheel(boardSize);
                  },
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSaladPizzaRow(),
                      const SizedBox(height: 16),
                      _buildRankingHistoryRow(),
                      const SizedBox(height: 16),
                      _buildResultRow(),
                      const SizedBox(height: 16),
                      _buildCoinListRow(),
                      const SizedBox(height: 16),
                      _buildBalanceRow(),
                      const SizedBox(height: 16),
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

  Widget _buildGameWheel(double boardSize) {
    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(boardBackgroundImage, width: boardSize, height: boardSize, fit: BoxFit.contain),
          ..._leafConfigs().asMap().entries.map((entry) {
            final int index = entry.key;
            final _LeafItemConfig config = entry.value;

            final double angle = config.angleDegrees * (math.pi / 180);
            final double radius = boardSize * config.radiusFactor;
            final double size = boardSize * config.sizeFactor;

            bool isHighlighted;
            if (_isSpinning) {
              isHighlighted = (index == _currentLeafIndex);
            } else if (_spinResultIndex != null) {
              isHighlighted = (index == _spinResultIndex);
            } else {
              isHighlighted = _isBettingTime; // Highlight all during betting time
            }

            return Transform(
              transform: Matrix4.translationValues(radius * math.cos(angle), radius * math.sin(angle), 0.0),
              child: _buildGameItem(config, index, size, isHighlighted, _bets[index] ?? 0),
            );
          }).toList(),
          Transform(
            transform: Matrix4.translationValues(
              boardSize * _centerConfig.offsetXFactor,
              boardSize * _centerConfig.offsetYFactor,
              0.0,
            ),
            child: _buildCenterDisplay(_centerConfig.assetPath, boardSize * _centerConfig.sizeFactor),
          ),
        ],
      ),
    );
  }

  Widget _buildGameItem(_LeafItemConfig config, int index, double size, bool isHighlighted, int betAmount) {
    return InkWell(
      onTap: () => _onBet(index),
      onLongPress: () => _onRemoveBet(index),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Image.asset(
                config.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    child: const Center(child: Icon(Icons.warning, color: Colors.red)),
                  );
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                color: isHighlighted ? Colors.transparent : Colors.black.withOpacity(0.5),
              ),
              // Show bet amount and multiplier
              if (betAmount > 0)
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatBetAmount(betAmount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.1,
                          shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
                        ),
                      ),
                      Text(
                        'x${config.multiplier}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.1,
                          shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
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
  }

  /// Center display shows countdown or "Spinning"
  Widget _buildCenterDisplay(String assetPath, double size) {
    String centerText = '';
    if (_isBettingTime) {
      centerText = '$_countdownSeconds';
    } else if (_isSpinning) {
      centerText = '...';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.contain,
          onError: (exception, stackTrace) {
            print('Error loading center image: $exception');
          },
        ),
      ),
      child: Center(
        child: Text(
          centerText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
          ),
        ),
      ),
    );
  }

  Widget _buildSaladPizzaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildFoodImage(_saladImagePath, "SALAD"), _buildFoodImage(_pizzaImagePath, "PIZZA")],
    );
  }

  Widget _buildFoodImage(String assetPath, String label) {
    return Column(
      children: [
        Image.asset(
          assetPath,
          height: 80,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.fastfood, color: Colors.white, size: 80),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRankingHistoryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text(
                "Today Ranking",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkLight.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text(
                "Your History",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.pink.withOpacity(0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      height: 100,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Result",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: _winningResultsHistory.map((path) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.asset(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Icon(Icons.circle, color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinListRow() {
    return Row(
      children: _coinValues.entries.map((entry) {
        final String path = entry.key;
        final int value = entry.value;
        final bool isSelected = _selectedCoinValue == value;

        return Expanded(
          child: InkWell(
            onTap: _isBettingTime
                ? () {
                    setState(() {
                      _selectedCoinValue = value;
                    });
                  }
                : null,
            child: Opacity(
              opacity: _isBettingTime ? 1.0 : 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.amber, width: 3) : null,
                  boxShadow: isSelected ? [const BoxShadow(color: Colors.amber, blurRadius: 10, spreadRadius: 2)] : [],
                ),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.monetization_on, color: Colors.white, size: 60),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildBalanceDisplay(title: "Balance", amount: _formatCurrency(_balance)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBalanceDisplay(title: "Today's Revenue", amount: _formatCurrency(_todaysRevenue)),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay({required String title, required String amount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
