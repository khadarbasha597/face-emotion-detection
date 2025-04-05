/// Lock screen widget that provides security for the application.
///
/// This widget is responsible for:
/// - Displaying a secure lock interface
/// - Handling authentication attempts
/// - Managing transitions between locked and unlocked states
/// - Providing access to the main application features

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';

class LockScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const LockScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  late AnimationController _unlockController;
  late AnimationController _arrowController;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _arrowAnimation;
  double _dragProgress = 0.0;
  final double _containerWidth = 400.0;

  /// Initializes the lock screen state and animations
  @override
  void initState() {
    super.initState();
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _slideUpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _blurAnimation = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _widthAnimation = Tween<double>(begin: _containerWidth, end: 300.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _heightAnimation = Tween<double>(begin: 80.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _borderRadiusAnimation = Tween<double>(begin: 40.0, end: 25.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _arrowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  /// Handles the unlock process and navigation
  void _handleUnlock() {
    if (_dragProgress > 0.5) {
      _unlockController.forward().then((_) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: widget.cameras,
        );
      });
    } else {
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragProgress += details.delta.dx / _containerWidth;
      _dragProgress = _dragProgress.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _handleUnlock();
  }

  /// Builds the lock screen interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, child) {
              return BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: const Color(0xFFFFAB40).withOpacity(0.3),
                ),
              );
            },
          ),

          // Main content
          AnimatedBuilder(
            animation: _unlockController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -MediaQuery.of(context).size.height *
                      0.4 *
                      _slideUpAnimation.value,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Swipe instruction with animated arrow
                        AnimatedBuilder(
                          animation: _arrowAnimation,
                          builder: (context, child) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Swipe right to unlock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: _arrowAnimation.value),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Lock rectangle
                        Container(
                          width: _widthAnimation.value,
                          height: _heightAnimation.value,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade300,
                            borderRadius: BorderRadius.circular(
                              _borderRadiusAnimation.value,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onHorizontalDragUpdate: _onHorizontalDragUpdate,
                            onHorizontalDragEnd: _onHorizontalDragEnd,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Lock icons and text
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Icon(
                                        Icons.lock_open,
                                        color: Colors.black.withOpacity(0.6),
                                        size: 24,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        _dragProgress > 0.5
                                            ? 'FED unlocked'
                                            : 'FED',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: Icon(
                                        Icons.lock_outline,
                                        color: Colors.black.withOpacity(0.6),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                // Slider thumb
                                Transform.translate(
                                  offset: Offset(
                                    _dragProgress *
                                        (_widthAnimation.value -
                                            _heightAnimation.value),
                                    0,
                                  ),
                                  child: Container(
                                    width: _heightAnimation.value,
                                    height: _heightAnimation.value,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _dragProgress > 0.5
                                          ? Icons.lock_open
                                          : Icons.lock_outline,
                                      color: Colors.orange.shade300,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  /// Cleans up animation controllers
  @override
  void dispose() {
    _unlockController.dispose();
    _arrowController.dispose();
    super.dispose();
  }
}
