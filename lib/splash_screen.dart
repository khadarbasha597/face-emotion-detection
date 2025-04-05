import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'lock_screen.dart';

/// Splash screen widget that displays when the app first launches.
///
/// This widget is responsible for:
/// - Showing the app logo and name
/// - Providing a smooth transition to the main screen
/// - Initializing necessary resources

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SplashScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _fadeAnimation;

  final List<String> _letters = ['F', 'E', 'D'];
  final List<String> _words = ['Face', 'Emotion', 'Detection'];

  /// Initializes animations and sets up navigation
  @override
  void initState() {
    super.initState();

    // Fade animation setup with shorter duration
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation setup with shorter duration
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create slide animations for each letter with faster timing
    _slideAnimations = List.generate(
      3,
      (index) => Tween<Offset>(
        begin: Offset(0, 0.5 + (index * 0.3)),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.15,
            0.45 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Start animations immediately
    _fadeController.forward();
    _slideController.forward();

    // Reduce total display time
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted && widget.cameras.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    LockScreen(cameras: widget.cameras),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  /// Cleans up animation controllers
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Builds the splash screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated FED letters
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => SlideTransition(
                  position: _slideAnimations[index],
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        _letters[index],
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Animated full words with faster animations
            ...List.generate(
              3,
              (index) => SlideTransition(
                position: _slideAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Text(
                      _words[index],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
