import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/ad_service.dart';
import '../auth/login_screen.dart'; // Import for AppTheme
import '../home/home_screen.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  final StreamController<int> _controller = StreamController<int>();
  int _selectedValue = 0;
  bool _isSpinning = false;
  bool _isWaitingForAd = false;
  int _earnedPoints = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Adding history of points earned
  final List<PointsHistory> _pointsHistory = [];

  final List<int> _rewards = [10, 25, 50, 100, 25, 10, 50, 25];
  final List<Color> _colors = [
    AppTheme.primaryColor.withOpacity(0.9),
    AppTheme.secondaryColor.withOpacity(0.9),
    AppTheme.accentColor.withOpacity(0.9),
    const Color(0xFF42A5F5), // Light Blue
    AppTheme.primaryColor.withOpacity(0.7),
    AppTheme.secondaryColor.withOpacity(0.7),
    AppTheme.accentColor.withOpacity(0.7),
    const Color(0xFF42A5F5).withOpacity(0.7),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.repeat(reverse: true);

    // Load sample history data - in a real app, this would come from a database
    _loadSamplePointsHistory();
  }

  @override
  void dispose() {
    _controller.close();
    _animationController.dispose();
    super.dispose();
  }

  void _loadSamplePointsHistory() {
    // This would normally be loaded from Firebase
    final now = DateTime.now();
    _pointsHistory.addAll([
      PointsHistory(
        amount: 25,
        source: 'Daily Spin',
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
      PointsHistory(
        amount: 50,
        source: 'Daily Spin',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      PointsHistory(
        amount: 10,
        source: 'Daily Spin',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      PointsHistory(
        amount: 100,
        source: 'Referral Bonus',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      PointsHistory(
        amount: 25,
        source: 'Daily Spin',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ]);
  }

  void _spinWheel(UserModel user) async {
    if (_isSpinning || _isWaitingForAd) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if user has reached max spins
    if (user.spinsToday >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('You\'ve reached the maximum 5 spins for today!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    // Select a random value
    Random random = Random();
    int randomValue = random.nextInt(_rewards.length);

    // Add the random value to the stream
    _controller.add(randomValue);

    // Wait for the wheel to stop spinning
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isSpinning = false;
      _isWaitingForAd = true;
      _selectedValue = randomValue;
    });

    // Show rewarded ad
    bool adWatched = await AdService().showRewardedAd();

    // Process the spin and update points
    if (adWatched) {
      int earnedPoints = await userProvider.processSpin();

      // Add to history
      if (earnedPoints > 0) {
        _pointsHistory.insert(
          0,
          PointsHistory(
            amount: earnedPoints,
            source: 'Daily Spin',
            timestamp: DateTime.now(),
          ),
        );
      }

      setState(() {
        _earnedPoints = earnedPoints;
        _isWaitingForAd = false;
      });

      // Show reward dialog
      _showRewardDialog(earnedPoints);
    } else {
      setState(() {
        _isWaitingForAd = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('You need to watch the ad to get your reward!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  void _showRewardDialog(int points) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: Row(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: AppTheme.accentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber.shade600,
                            size: 70,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Text(
                    '🎉 You won $points points! 🎉',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keep spinning to earn more rewards!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'AWESOME!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.only(bottom: 24),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Spin & Win',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      maxChildSize: 0.95,
                      minChildSize: 0.5,
                      builder:
                          (context, scrollController) => Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: _buildPointsHistorySheet(scrollController),
                          ),
                    ),
              );
            },
            icon: const Icon(Icons.history, color: AppTheme.primaryColor),
            tooltip: 'Points History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  Color(0xFF1976D2), // Slightly darker blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Points',
                  '${user.points}',
                  Icons.monetization_on_rounded,
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildStatItem(
                  'Spins Today',
                  '${user.spinsToday}/5',
                  Icons.rotate_right_rounded,
                ),
              ],
            ),
          ),

          // Fortune Wheel
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Spin to win rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FortuneWheel(
                      animateFirst: false,
                      selected: _controller.stream,
                      physics: CircularPanPhysics(
                        duration: const Duration(seconds: 1),
                        curve: Curves.decelerate,
                      ),
                      indicators: const [
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(color: AppTheme.accentColor),
                        ),
                      ],
                      styleStrategy: UniformStyleStrategy(
                        borderColor: Colors.white,
                        borderWidth: 2,
                      ),
                      items: List.generate(
                        _rewards.length,
                        (index) => FortuneItem(
                          style: FortuneItemStyle(
                            color: _colors[index],
                            borderWidth: 0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: Text(
                              '${_rewards[index]}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Spin Button
          Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            width: double.infinity,
            height: 60,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap:
                    _isSpinning || _isWaitingForAd
                        ? null
                        : () => _spinWheel(user),
                child: Center(
                  child:
                      _isSpinning
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                          : _isWaitingForAd
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_filled_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Watch Ad to Get Reward',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_animation.value * 0.05),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.rotate_right_rounded,
                                      color: Colors.white,
                                      size: 28 + (_animation.value * 2),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'SPIN NOW',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsHistorySheet(ScrollController scrollController) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),

        // Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                'Points Earning History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Filter chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Chip(
            label: const Text('Last 30 days'),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            labelStyle: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
            avatar: const Icon(
              Icons.date_range,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Points history list
        Expanded(
          child:
              _pointsHistory.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No points history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Spin the wheel to start earning points!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _pointsHistory.length,
                    itemBuilder: (context, index) {
                      final historyItem = _pointsHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '+${historyItem.amount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            historyItem.source,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(historyItem.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Model class for points history
class PointsHistory {
  final int amount;
  final String source;
  final DateTime timestamp;

  PointsHistory({
    required this.amount,
    required this.source,
    required this.timestamp,
  });
}
