import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../screens/auth/login_screen.dart'; // Import for AppTheme

// Fallback colors in case AppTheme is not properly imported
class _FallbackTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Vibrant blue
  static const Color secondaryColor = Color(0xFF26A69A); // Teal
  static const Color accentColor = Color(0xFFFFB300); // Amber
}

// Simple particle class to represent floating coins in the background
class Particle {
  late Offset position;
  late double size;
  late double speed;
  late double opacity;
  late double direction;

  Particle(Size screenSize) {
    final random = math.Random();
    position = Offset(
      random.nextDouble() * screenSize.width,
      random.nextDouble() * screenSize.height,
    );
    size = random.nextDouble() * 15 + 5; // Random size between 5 and 20
    speed = random.nextDouble() * 2 + 0.5; // Random speed between 0.5 and 2.5
    opacity =
        random.nextDouble() * 0.2 +
        0.05; // Random opacity between 0.05 and 0.25
    direction =
        random.nextDouble() * 2 * math.pi; // Random direction in radians
  }

  void update(Size screenSize) {
    final random = math.Random();
    // Move the particle
    position = Offset(
      position.dx + math.cos(direction) * speed,
      position.dy + math.sin(direction) * speed,
    );

    // If the particle goes off-screen, reset it
    if (position.dx < 0 ||
        position.dx > screenSize.width ||
        position.dy < 0 ||
        position.dy > screenSize.height) {
      position = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
      direction = random.nextDouble() * 2 * math.pi;
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _progressOpacityAnimation;

  bool _isConnected = true;
  bool _hasAdBlocker = false;
  String _errorMessage = '';
  Timer? _connectivityTimer;
  final Connectivity _connectivity = Connectivity();

  // Particles for background animation
  final List<Particle> _particles = [];

  // Get the primaryColor (with fallback if AppTheme is not available)
  Color get primaryColor {
    try {
      return AppTheme.primaryColor;
    } catch (e) {
      return _FallbackTheme.primaryColor;
    }
  }

  // Get the accentColor (with fallback if AppTheme is not available)
  Color get accentColor {
    try {
      return AppTheme.accentColor;
    } catch (e) {
      return _FallbackTheme.accentColor;
    }
  }

  @override
  void initState() {
    super.initState();

    // Start checking connectivity right away
    _checkConnectivity();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Slightly faster animations
      vsync: this,
    );

    // Rotation animation for the coin
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Scale animation for the coin
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Opacity animation for the coin
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Opacity animation for text
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    // Opacity animation for progress indicator
    _progressOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    // Initialize particles after a short delay to get the screen size
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          final size = MediaQuery.of(context).size;
          for (int i = 0; i < 20; i++) {
            _particles.add(Particle(size));
          }
        });
      }
    });

    _controller.forward();

    // Start a ticker for the particle animation
    _startParticleAnimation();

    // Set up periodic connectivity check
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;

      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _errorMessage =
                'No internet connection. Please check your network settings.';
          });
        }
        return;
      }

      // If we have connection but had an error before, we'll clear it
      if (!_isConnected && mounted) {
        setState(() {
          _isConnected = true;
          _errorMessage = '';
        });
      }

      // We only need to check for ad blockers if we have a connection
      await _checkAdBlocker();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to check connectivity. The app will continue loading.';
        });
      }
    }
  }

  Future<void> _checkAdBlocker() async {
    try {
      // This is a simplified check. In a real app, you would:
      // 1. Make a request to a known ad server
      // 2. If it fails with a specific error pattern, it might be an ad blocker

      // For this example, we're just returning a mock result
      // In a real implementation, you would attempt to load an ad or
      // make a request to a tracking domain and see if it's blocked

      // Mock implementation - in real code, replace with actual detection
      final adBlockerDetected = false; // Replace with actual detection

      if (adBlockerDetected && mounted) {
        setState(() {
          _hasAdBlocker = true;
          _errorMessage =
              'Ad blocker detected. Some features may not work properly.';
        });
      }
    } catch (e) {
      // If there's an error checking for ad blockers but we have connectivity,
      // we'll assume everything is fine and continue
    }
  }

  void _startParticleAnimation() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          final size = MediaQuery.of(context).size;
          for (var particle in _particles) {
            particle.update(size);
          }
        });
        _startParticleAnimation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: size.width,
          height: size.height,
          color: Colors.white,
          child: Stack(
            children: [
              // Particle overlay
              if (_particles.isNotEmpty)
                CustomPaint(
                  size: size,
                  painter: ParticlePainter(
                    particles: _particles,
                    color: accentColor,
                  ),
                ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with Glow Effect
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _opacityAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/new.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        // Fallback to built-in icon if image fails to load
                                        return Icon(
                                          Icons.monetization_on,
                                          size: 80,
                                          color: accentColor,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // App name with staggered animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'SPIN TO EARN',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 2,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Spin & Win Real Money',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey[700],
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 50),

                    // Error message or loading indicator
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _progressOpacityAnimation.value,
                          child: Column(
                            children: [
                              if (_errorMessage.isNotEmpty)
                                _buildErrorWidget()
                              else
                                Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildErrorWidget() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _isConnected
                ? const Color(0xFFFFF9E0) // Light yellow for ad blocker warning
                : const Color(0xFFFFEBEE), // Light red for no connection error
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isConnected ? AppTheme.warningColor : AppTheme.errorColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isConnected ? Icons.warning_amber : Icons.signal_wifi_off,
                color:
                    _isConnected ? AppTheme.warningColor : AppTheme.errorColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color:
                        _isConnected
                            ? AppTheme.warningColor.withOpacity(0.8)
                            : AppTheme.errorColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _checkConnectivity();
                if (!_isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trying to reconnect...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isConnected ? AppTheme.warningColor : AppTheme.errorColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Continue to the app anyway
              setState(() {
                _errorMessage = '';
              });
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  _isConnected ? AppTheme.warningColor : AppTheme.errorColor,
            ),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint =
          Paint()
            ..color = color.withOpacity(particle.opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
