import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../providers/user_provider.dart';
import '../../services/ad_service.dart';
import '../spin/spin_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart'; // Import for AppTheme

// Define our app theme colors
class AppColors {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color secondary = Color(0xFF4527A0); // Deep Purple 700
  static const Color accent = Color(0xFFAB47BC); // Purple 400
  static const Color background = Color(0xFFF5F5F5); // Grey 100
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB71C1C); // Red 900
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF212121); // Grey 900
  static const Color onSurface = Color(0xFF212121); // Grey 900
  static const Color onError = Colors.white;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const SpinScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAttemptingAdLoad = false;
  int _adRetryAttempt = 0;
  static const int _maxAdRetryAttempts = 3;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation controller for nav bar animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    // Use a slight delay to ensure AdService is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadBannerAd();
    });
    _showWelcomeBackDialog();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (_isAttemptingAdLoad || _adRetryAttempt >= _maxAdRetryAttempts) return;

    setState(() {
      _isAttemptingAdLoad = true;
    });

    debugPrint('Attempting to load banner ad, attempt #${_adRetryAttempt + 1}');

    BannerAd? bannerAd = AdService().createBannerAd();

    if (bannerAd != null) {
      bannerAd
          .load()
          .then((value) {
            setState(() {
              _bannerAd = bannerAd;
              _isAdLoaded = true;
              _isAttemptingAdLoad = false;
              debugPrint('Banner ad loaded successfully');
            });
          })
          .catchError((error) {
            debugPrint('Error loading banner ad: $error');
            _bannerAd = null;
            _isAdLoaded = false;
            _isAttemptingAdLoad = false;

            // Retry loading ads after a delay
            if (_adRetryAttempt < _maxAdRetryAttempts) {
              _adRetryAttempt++;
              Future.delayed(const Duration(seconds: 2), () {
                _loadBannerAd();
              });
            }
          });
    } else {
      debugPrint('Banner ad creation returned null');
      setState(() {
        _isAttemptingAdLoad = false;
      });

      // Retry after initializing AdService
      if (_adRetryAttempt < _maxAdRetryAttempts) {
        _adRetryAttempt++;
        Future.delayed(const Duration(seconds: 2), () async {
          await AdService().initialize();
          _loadBannerAd();
        });
      }
    }
  }

  void _showWelcomeBackDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dailyBonus = userProvider.dailyBonus;

      if (dailyBonus > 0) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: AppTheme.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Welcome Back!',
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.secondaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Bonus',
                                style: TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${(dailyBonus / 1000).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$dailyBonus points',
                                style: TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Come back tomorrow for another daily bonus!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppTheme.accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'AWESOME!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
                actionsPadding: const EdgeInsets.only(bottom: 16),
              ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdLoaded && _bannerAd != null)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: const Border(
                  top: BorderSide(color: Colors.black12, width: 0.5),
                ),
              ),
              height: _bannerAd!.size.height.toDouble(),
              width: double.infinity,
              child: AdWidget(ad: _bannerAd!),
            ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _animation.value)),
                child: Opacity(
                  opacity: _animation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        if (index != _currentIndex) {
                          setState(() {
                            _currentIndex = index;
                          });

                          // Reset animation for smooth tab transition
                          _controller.reset();
                          _controller.forward();

                          // Show interstitial ad when navigating between tabs (occasionally)
                          if (_currentIndex != 0 &&
                              index != 0 &&
                              DateTime.now().second % 4 == 0) {
                            AdService().showInterstitialAd();
                          }
                        }
                      },
                      backgroundColor: AppTheme.surfaceColor,
                      selectedItemColor: AppTheme.primaryColor,
                      unselectedItemColor: Colors.grey.shade400,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      items: [
                        _buildNavItem(
                          Icons.rotate_right_rounded,
                          Icons.rotate_right_rounded,
                          'Spin',
                        ),
                        _buildNavItem(
                          Icons.account_balance_wallet_outlined,
                          Icons.account_balance_wallet,
                          'Wallet',
                        ),
                        _buildNavItem(
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}
