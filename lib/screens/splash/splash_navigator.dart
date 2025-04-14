import 'package:flutter/material.dart';
import 'dart:async';

import '../splash/splash_screen.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

class SplashNavigator extends StatefulWidget {
  final Widget child;

  const SplashNavigator({super.key, required this.child});

  @override
  State<SplashNavigator> createState() => _SplashNavigatorState();
}

class _SplashNavigatorState extends State<SplashNavigator>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _isInitialized = false;
  late Widget _nextScreen;
  bool _forceNavigate = false;

  // Use a controller to ensure smooth animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Cache the next screen to avoid rebuild delays
    _nextScreen = widget.child;

    // Set up fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start navigation after a frame is rendered to prevent jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToApp();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToApp() async {
    // Pre-warm the next screen by building it in memory
    _nextScreen = widget.child;

    // Show splash for at least 3 seconds (minimum time for animation)
    final minSplashDuration = Future.delayed(
      const Duration(milliseconds: 3000),
    );

    // Wait for initialization (like user provider loading)
    final initializationComplete = Future.delayed(
      const Duration(milliseconds: 100),
      () async {
        // Wait until UserProvider is done initializing
        while (!_isInitialized && !_forceNavigate) {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          _isInitialized = !userProvider.isLoading;
          if (!_isInitialized) {
            // Check again after a short delay
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        return true;
      },
    );

    // Force navigation after a maximum timeout (8 seconds)
    // This ensures the app loads even if there are connectivity issues
    Future.delayed(const Duration(milliseconds: 8000), () {
      if (mounted && _showSplash) {
        setState(() {
          _forceNavigate = true;
        });
      }
    });

    // Wait for both conditions to be met before navigating
    await Future.wait([minSplashDuration, initializationComplete]);

    if (mounted) {
      // Start fade out animation
      _fadeController.forward();

      // Wait for animation to complete before transitioning
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Always have the destination screen ready in the background
        // This prevents the black flash between screens
        _nextScreen,

        // Show splash screen with fade animation
        if (_showSplash)
          FadeTransition(
            opacity: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_fadeAnimation),
            child: const SplashScreen(),
          ),
      ],
    );
  }
}
