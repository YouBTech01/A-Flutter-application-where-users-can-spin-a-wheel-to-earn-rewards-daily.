import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/user_provider.dart';
import '../../models/user_model.dart'; // Import UserModel
import '../auth/login_screen.dart'; // Import for AppTheme

// Define the Achievement class to track user achievements
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.progress,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isUpdatingUpi = false;
  bool _isApplyingReferral = false;

  // New animation controller
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Tab selection for statistics
  int _selectedStatTab = 0;

  // List of achievements for the user to earn
  final List<Achievement> _achievements = [
    Achievement(
      title: 'First Spin',
      description: 'Spin the wheel for the first time',
      icon: Icons.rotate_right,
      isUnlocked: true,
      progress: 1.0,
    ),
    Achievement(
      title: 'Daily Spinner',
      description: 'Spin the wheel for 7 consecutive days',
      icon: Icons.calendar_today,
      isUnlocked: false,
      progress: 0.43, // 3 out of 7 days
    ),
    Achievement(
      title: 'First Withdrawal',
      description: 'Make your first withdrawal',
      icon: Icons.account_balance_wallet,
      isUnlocked: false,
      progress: 0.0,
    ),
    Achievement(
      title: 'High Roller',
      description: 'Collect over 25,000 points',
      icon: Icons.attach_money,
      isUnlocked: false,
      progress: 0.3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _upiController.dispose();
    _referralController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateUpiId(UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingUpi = true;
    });

    try {
      await userProvider.updateUpiId(_upiController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('UPI ID updated successfully!')),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to update UPI ID: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      setState(() {
        _isUpdatingUpi = false;
      });
    }
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

    // Set initial value for UPI ID field
    _upiController.text = user.upiId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
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
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.errorColor),
                          const SizedBox(width: 12),
                          const Text('Sign Out'),
                        ],
                      ),
                      content: const Text(
                        'Are you sure you want to sign out?',
                        style: TextStyle(fontSize: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            userProvider.signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
              );
            },
            icon: Icon(Icons.logout, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with User Info
            _buildProfileHeader(user),

            // Statistics Section
            _buildStatisticsSection(user),

            // Achievements Section
            _buildAchievementsSection(),

            // Verification Status Section - New trust indicator
            _buildVerificationSection(user),

            // UPI ID Section
            _buildUpiSection(userProvider),

            // Customer Support Section - New helpful section
            _buildSupportSection(),

            // App Info
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Edit Button
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : user.email[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Joined ${DateFormat('dd MMM yyyy').format(user.lastLoginDate)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildVerificationBadge(
                            'Verified',
                            Icons.verified,
                            true,
                          ),
                          const SizedBox(width: 8),
                          _buildVerificationBadge(
                            'VIP',
                            Icons.star,
                            user.points > 10000,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reward Points and Levels Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat(
                  'Level',
                  _calculateUserLevel(user.points),
                  Icons.trending_up,
                ),
                _buildDivider(),
                _buildQuickStat(
                  'Rank',
                  _calculateUserRank(user.points),
                  Icons.emoji_events_outlined,
                ),
                _buildDivider(),
                _buildQuickStat(
                  'Days',
                  _calculateDaysActive(user.lastLoginDate),
                  Icons.date_range,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentColor : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  String _calculateUserLevel(int points) {
    // Simple level calculation based on points
    int level = (points / 5000).floor() + 1;
    return level.toString();
  }

  String _calculateUserRank(int points) {
    if (points >= 50000) return 'Diamond';
    if (points >= 25000) return 'Gold';
    if (points >= 10000) return 'Silver';
    return 'Bronze';
  }

  String _calculateDaysActive(DateTime lastLoginDate) {
    // Calculate days since registration
    int days = DateTime.now().difference(lastLoginDate).inDays + 1;
    return days.toString();
  }

  Widget _buildStatisticsSection(UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.query_stats, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Current Points',
                user.points.toString(),
                Icons.star,
              ),
              _buildStatItem(
                'Total Earnings',
                '₹${(user.totalEarnings / 1000).toStringAsFixed(2)}',
                Icons.account_balance_wallet,
              ),
              _buildStatItem(
                'Spins Today',
                '${user.spinsToday}/5',
                Icons.rotate_right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '1/4 Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(_achievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color:
            achievement.isUnlocked
                ? AppTheme.primaryColor
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                achievement.isUnlocked
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (achievement.isUnlocked)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: AppTheme.accentColor, size: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  achievement.icon,
                  color:
                      achievement.isUnlocked
                          ? Colors.white
                          : Colors.grey.shade700,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        achievement.isUnlocked
                            ? Colors.white
                            : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        achievement.isUnlocked
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: achievement.progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  color:
                      achievement.isUnlocked
                          ? AppTheme.accentColor
                          : Colors.grey.shade400,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryColor,
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your account is secure and protected',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVerificationItem('Identity', true, Icons.person_outline),
              _buildVerificationItem('Email', true, Icons.email_outlined),
              _buildVerificationItem(
                'Payment',
                user.upiId.isNotEmpty,
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String label, bool isVerified, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isVerified ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                isVerified
                    ? AppTheme.secondaryColor
                    : Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          isVerified ? 'Verified' : 'Pending',
          style: TextStyle(
            color: isVerified ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUpiSection(UserProvider userProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'UPI ID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(
                            0.2 + (0.1 * _animation.value),
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'For Withdrawals',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Update your UPI ID for withdrawals',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _upiController,
                    decoration: InputDecoration(
                      labelText: 'UPI ID',
                      labelStyle: TextStyle(color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: AppTheme.primaryColor,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@')) {
                        return 'Please enter a valid UPI ID';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isUpdatingUpi
                            ? null
                            : () => _updateUpiId(userProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isUpdatingUpi
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Update',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Customer Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'re here to help. Contact us if you have any questions or need assistance.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'support@spintoearn.com',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.question_answer_outlined,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAQs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse our frequently asked questions',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('App Version'),
                  subtitle: const Text('Version 1.0.0 (Build 10)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Latest',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('Security & Privacy'),
                  subtitle: const Text('Your data is secure with us'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildPrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppTheme.accentColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Rules for using our app'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildTermsOfServiceScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('Rate Our App'),
                  subtitle: const Text('Love Spin to Earn? Rate us!'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: AppTheme.accentColor, size: 16),
                      Icon(Icons.star, color: AppTheme.accentColor, size: 16),
                      Icon(Icons.star, color: AppTheme.accentColor, size: 16),
                      Icon(Icons.star, color: AppTheme.accentColor, size: 16),
                      Icon(
                        Icons.star_half,
                        color: AppTheme.accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                  onTap: () {
                    // This would normally open the app store
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Thank you for rating our app!'),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '© 2023 Spin to Earn',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'All rights reserved',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Privacy Policy Screen
  Widget _buildPrivacyPolicyScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildPolicyHeader('Privacy Policy for Spin to Earn'),
            _buildPolicyDate('Last Updated: June 15, 2023'),

            _buildPolicySectionTitle('1. Information We Collect'),
            _buildPolicyText('We collect the following types of information:'),
            _buildPolicyBulletPoint(
              'Personal Information: Email address, name, and UPI ID for withdrawals.',
            ),
            _buildPolicyBulletPoint(
              'Usage Data: Information about how you use the app, including spin history and rewards earned.',
            ),
            _buildPolicyBulletPoint(
              'Device Information: Device type, operating system, and unique device identifiers.',
            ),

            _buildPolicySectionTitle('2. How We Use Your Information'),
            _buildPolicyText('We use the collected information for:'),
            _buildPolicyBulletPoint(
              'Providing and maintaining the app functionality',
            ),
            _buildPolicyBulletPoint('Processing withdrawal requests'),
            _buildPolicyBulletPoint('Tracking referrals and rewarding users'),
            _buildPolicyBulletPoint(
              'Improving user experience and app performance',
            ),
            _buildPolicyBulletPoint(
              'Communicating with you about rewards and updates',
            ),

            _buildPolicySectionTitle('3. Data Sharing and Disclosure'),
            _buildPolicyText('We may share your information with:'),
            _buildPolicyBulletPoint(
              'Service providers who help us operate the app',
            ),
            _buildPolicyBulletPoint(
              'Payment processors for processing withdrawals',
            ),
            _buildPolicyBulletPoint('Legal authorities when required by law'),

            _buildPolicySectionTitle('4. Data Security'),
            _buildPolicyText(
              'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or disclosure. However, no method of transmission over the internet or electronic storage is completely secure.',
            ),

            _buildPolicySectionTitle('5. Your Rights'),
            _buildPolicyText('You have the right to:'),
            _buildPolicyBulletPoint('Access your personal information'),
            _buildPolicyBulletPoint('Correct inaccurate information'),
            _buildPolicyBulletPoint('Request deletion of your information'),
            _buildPolicyBulletPoint('Withdraw consent at any time'),

            _buildPolicySectionTitle('6. Children\'s Privacy'),
            _buildPolicyText(
              'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),

            _buildPolicySectionTitle('7. Changes to This Policy'),
            _buildPolicyText(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date.',
            ),

            _buildPolicySectionTitle('8. Contact Us'),
            _buildPolicyText(
              'If you have any questions or concerns about our Privacy Policy, please contact us at:',
            ),
            _buildPolicyText('support@spintoearn.com', isBold: true),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Terms of Service Screen
  Widget _buildTermsOfServiceScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildPolicyHeader('Terms of Service for Spin to Earn'),
            _buildPolicyDate('Last Updated: June 15, 2023'),

            _buildPolicySectionTitle('1. Acceptance of Terms'),
            _buildPolicyText(
              'By accessing or using the Spin to Earn app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.',
            ),

            _buildPolicySectionTitle('2. Description of Service'),
            _buildPolicyText(
              'Spin to Earn is a mobile application that allows users to earn rewards by spinning a virtual wheel. Rewards can be withdrawn to the user\'s UPI account once certain conditions are met.',
            ),

            _buildPolicySectionTitle('3. Eligibility'),
            _buildPolicyText(
              'You must be at least 18 years old to use this app. By using the app, you represent and warrant that you are 18 years of age or older and are able to form a legally binding contract.',
            ),

            _buildPolicySectionTitle('4. User Accounts'),
            _buildPolicyText(
              'To use certain features of the app, you must register for an account. You agree to provide accurate and complete information when creating your account and to update your information to keep it accurate and current.',
            ),

            _buildPolicySectionTitle('5. Rewards and Withdrawals'),
            _buildPolicyText(
              '5.1 Spinning Limits: Users are limited to 5 spins per day.',
            ),
            _buildPolicyText(
              '5.2 Minimum Withdrawal: The minimum amount for withdrawal is ₹50.',
            ),
            _buildPolicyText(
              '5.3 Withdrawal Processing: Withdrawals may take up to 7 business days to process.',
            ),
            _buildPolicyText(
              '5.4 Validation: We reserve the right to validate user activity before processing withdrawals.',
            ),

            _buildPolicySectionTitle('6. Referral Program'),
            _buildPolicyText(
              '6.1 Earnings: Users earn ₹2 for each new user they refer who signs up using their referral code.',
            ),
            _buildPolicyText(
              '6.2 Validity: Referral rewards are credited only after the referred user completes at least one spin.',
            ),
            _buildPolicyText(
              '6.3 Restrictions: Self-referrals or creating multiple accounts to claim referral rewards is prohibited.',
            ),

            _buildPolicySectionTitle('7. Prohibited Activities'),
            _buildPolicyText('You agree not to:'),
            _buildPolicyBulletPoint(
              'Use automated systems or bots to interact with the app',
            ),
            _buildPolicyBulletPoint(
              'Create multiple accounts to exceed daily spin limits',
            ),
            _buildPolicyBulletPoint(
              'Engage in fraudulent activities to earn rewards',
            ),
            _buildPolicyBulletPoint(
              'Attempt to manipulate or bypass the app\'s intended functionality',
            ),
            _buildPolicyBulletPoint(
              'Sell, trade, or transfer your account to another person',
            ),

            _buildPolicySectionTitle('8. Termination'),
            _buildPolicyText(
              'We reserve the right to suspend or terminate your account at any time for violations of these terms or for any other reason at our sole discretion.',
            ),

            _buildPolicySectionTitle('9. Limitation of Liability'),
            _buildPolicyText(
              'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the app.',
            ),

            _buildPolicySectionTitle('10. Changes to Terms'),
            _buildPolicyText(
              'We may modify these Terms of Service at any time. Continued use of the app after any such changes constitutes your acceptance of the new terms.',
            ),

            _buildPolicySectionTitle('11. Contact Information'),
            _buildPolicyText(
              'If you have any questions about these Terms, please contact us at:',
            ),
            _buildPolicyText('support@spintoearn.com', isBold: true),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widgets for policy screens
  Widget _buildPolicyHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }

  Widget _buildPolicyDate(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPolicySectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPolicyText(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }

  Widget _buildPolicyBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.primaryText,
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
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryText,
          ),
        ),
      ],
    );
  }
}
