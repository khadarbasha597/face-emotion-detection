import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Main screen of the application that handles camera preview and face detection.
///
/// This widget is responsible for:
/// - Camera initialization and preview
/// - Face detection and emotion analysis
/// - Displaying emoji rain effects
/// - Handling camera switching
/// - Managing app state and UI updates

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MyHomePage({super.key, required this.cameras});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  String _emotion = "Detecting...";
  int _cameraIndex = 0;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isProcessing = false;
  Rect? _faceRect;
  DateTime? _lastEmotionUpdate;
  static const Duration emotionUpdateDelay = Duration(milliseconds: 400);
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _lockController;
  late Animation<double> _lockSlideAnimation;
  late Animation<double> _lockScaleAnimation;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _lockController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _lockSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _lockScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _transitionController.forward();
  }

  void _initializeFaceDetector() {
    try {
      print('Initializing face detector...');
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.15,
          enableTracking: true,
        ),
      );
      print('Face detector initialized successfully');
    } catch (e) {
      print('Error initializing face detector: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _errorMessage = 'Failed to initialize face detection';
      });
    }
  }

  /// Initializes the camera and sets up face detection
  Future<void> _initializeCamera() async {
    try {
      print('Initializing camera...');

      if (_cameraController != null) {
        print('Disposing old camera controller');
        await _cameraController!.dispose();
      }

      final camera = widget.cameras[_cameraIndex];
      final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      print('Camera direction: ${camera.lensDirection}');

      print('Creating new camera controller for camera ${camera.name}');
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      print('Initializing camera controller...');
      await _cameraController!.initialize();

      if (!mounted) {
        print('Widget not mounted, stopping initialization');
        return;
      }

      print('Setting camera modes...');
      await Future.wait([
        _cameraController!.setFlashMode(FlashMode.off),
        _cameraController!.setExposureMode(ExposureMode.auto),
        _cameraController!.setFocusMode(FocusMode.auto),
      ]);

      // Optimize camera settings based on camera type
      if (isFrontCamera) {
        await _cameraController!.setExposureOffset(1.2);
        await _cameraController!.setFocusMode(FocusMode.auto);
      } else {
        await _cameraController!.setExposureOffset(1.5);
        await _cameraController!.setFocusMode(FocusMode.auto);
      }

      print('Camera initialized successfully');
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });

      print('Starting face detection...');
      _startFaceDetection();
    } catch (e) {
      print('Error initializing camera: $e');
      print('Error stack trace: ${StackTrace.current}');
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
        _emotion = "Camera initialization error";
      });
    }
  }

  void _startFaceDetection() {
    print('Starting face detection...');
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera controller not ready for face detection');
      return;
    }

    print('Starting image stream...');
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting || _isProcessing) {
        return;
      }
      _isDetecting = true;
      try {
        await _detectFaces(image);
      } catch (e) {
        print('Error in face detection: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Processes camera images for face detection
  Future<void> _detectFaces(CameraImage image) async {
    if (_isProcessing) {
      print('Skipping face detection - already processing');
      return;
    }
    _isProcessing = true;

    try {
      print('Converting camera image...');
      final inputImage = _convertCameraImage(image);
      print('Image converted, processing face detection...');

      final faces = await _faceDetector.processImage(inputImage);
      print('Detected ${faces.length} faces');

      if (faces.isNotEmpty) {
        final face = faces.first;
        final double? smileProb = face.smilingProbability;
        final double? leftEyeOpenProb = face.leftEyeOpenProbability;
        final double? rightEyeOpenProb = face.rightEyeOpenProbability;

        print(
          'Face probabilities - Smile: $smileProb, Left Eye: $leftEyeOpenProb, Right Eye: $rightEyeOpenProb',
        );

        if (mounted) {
          final now = DateTime.now();
          if (_lastEmotionUpdate == null ||
              now.difference(_lastEmotionUpdate!) >= emotionUpdateDelay) {
            final newEmotion = _analyzeEmotion(
              smileProb,
              leftEyeOpenProb,
              rightEyeOpenProb,
            );

            if (newEmotion != _emotion) {
              setState(() {
                _emotion = newEmotion;
                _faceRect = face.boundingBox;
                _errorMessage = null;
                _lastEmotionUpdate = now;
              });
            }
          }
        }
      } else {
        print('No faces detected in the current frame');
        if (mounted) {
          setState(() {
            _emotion = "No face detected";
            _faceRect = null;
          });
        }
      }
    } catch (e) {
      print('Face detection error: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _emotion = "Error detecting face";
          _faceRect = null;
          _errorMessage = 'Face detection failed: $e';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _analyzeLighting(CameraImage image) async {
    try {
      final int totalPixels = image.width * image.height;
      int totalBrightness = 0;

      final Uint8List yPlane = image.planes[0].bytes;
      for (int i = 0; i < yPlane.length; i++) {
        totalBrightness += yPlane[i];
      }

      final double averageBrightness = totalBrightness / totalPixels;
      print('Average brightness: $averageBrightness');

      final isFrontCamera =
          widget.cameras[_cameraIndex].lensDirection ==
          CameraLensDirection.front;

      // Different thresholds for front and back cameras
      if (isFrontCamera) {
        if (averageBrightness < 70) {
          await _adjustExposure(0.8);
        } else if (averageBrightness > 180) {
          await _adjustExposure(-0.8);
        } else if (averageBrightness < 90) {
          await _adjustExposure(0.4);
        } else if (averageBrightness > 160) {
          await _adjustExposure(-0.4);
        }
      } else {
        // Back camera needs more light
        if (averageBrightness < 90) {
          await _adjustExposure(1.2);
        } else if (averageBrightness > 200) {
          await _adjustExposure(-0.6);
        } else if (averageBrightness < 120) {
          await _adjustExposure(0.8);
        } else if (averageBrightness > 180) {
          await _adjustExposure(-0.4);
        }
      }
    } catch (e) {
      print('Lighting analysis error: $e');
    }
  }

  Future<void> _adjustExposure(double adjustment) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.setExposureOffset(adjustment);
      print('Adjusted exposure offset to: $adjustment');
    } catch (e) {
      print('Error adjusting exposure: $e');
    }
  }

  /// Analyzes facial features to determine emotion
  String _analyzeEmotion(
    double? smileProb,
    double? leftEyeOpenProb,
    double? rightEyeOpenProb,
  ) {
    if (smileProb == null ||
        leftEyeOpenProb == null ||
        rightEyeOpenProb == null) {
      return "No face detected";
    }

    // More accurate emotion detection with adjusted thresholds
    if (smileProb < 0.15 && leftEyeOpenProb > 0.7 && rightEyeOpenProb > 0.7) {
      return "Angry 😠";
    }

    if (smileProb > 0.7) {
      return "Happy 😊";
    }

    if (smileProb < 0.25 && leftEyeOpenProb < 0.4 && rightEyeOpenProb < 0.4) {
      return "Sad 😢";
    }

    if (smileProb > 0.4 && smileProb < 0.6) {
      return "Neutral 🙂";
    }

    return "Detecting...";
  }

  /// Converts camera image format for face detection
  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Get rotation based on camera type
    final camera = widget.cameras[_cameraIndex];
    final imageRotation =
        camera.lensDirection == CameraLensDirection.front
            ? InputImageRotation
                .rotation270deg // Front camera: 270 degrees for proper face detection
            : InputImageRotation.rotation90deg; // Back camera: 90 degrees

    final inputImageFormat = InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  /// Switches between front and back cameras
  Future<void> _switchCamera() async {
    if (_cameraController == null) return;

    final newIndex = (_cameraIndex + 1) % widget.cameras.length;
    final newCamera = widget.cameras[newIndex];

    // First stop the current camera's image stream
    try {
      await _cameraController!.stopImageStream();
    } catch (e) {
      print('Error stopping image stream: $e');
    }

    // Dispose of the current camera
    final oldController = _cameraController;
    _cameraController = null;
    try {
      await oldController!.dispose();
    } catch (e) {
      print('Error disposing old camera: $e');
    }

    // Create new controller
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      // Initialize new camera
      await _cameraController!.initialize();

      setState(() {
        _cameraIndex = newIndex;
        _isInitialized = true;
        _faceRect = null;
        _emotion = "";
      });

      // Configure camera settings
      await Future.wait([
        _cameraController!.setFlashMode(FlashMode.off),
        _cameraController!.setExposureMode(ExposureMode.auto),
        _cameraController!.setFocusMode(FocusMode.auto),
      ]);

      _startFaceDetection();
    } catch (e) {
      print('Error during camera switch: $e');
      setState(() {
        _isInitialized = false;
        _emotion = "Camera error";
      });
    }
  }

  /// Locks the application
  void _handleLock() {
    setState(() {
      _isLocking = true;
    });

    // First animate to center
    _lockController.forward().then((_) {
      // Wait for 200ms to show the locked state
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacementNamed(
          context,
          '/lock',
          arguments: widget.cameras,
        );
      });
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _lockController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with improved styling
          if (_isInitialized &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                margin: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()..scale(
                            widget.cameras[_cameraIndex].lensDirection ==
                                    CameraLensDirection.front
                                ? -1.0
                                : 1.0,
                            1.0,
                          ),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
            ),

          // Face detection overlay
          if (_faceRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: FacePainter(
                  faceRect: _faceRect!,
                  previewSize: Size(
                    _cameraController!.value.previewSize!.height,
                    _cameraController!.value.previewSize!.width,
                  ),
                ),
              ),
            ),

          // Emoji Rain Animation
          if (_faceRect != null &&
              _emotion.isNotEmpty &&
              _emotion != "Detecting...")
            Positioned.fill(child: EmojiRain(emotion: _emotion.split(' ')[0])),

          // Emotion Display Container
          AnimatedBuilder(
            animation: _isLocking ? _lockController : _transitionController,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              final topPosition =
                  _isLocking
                      ? (screenHeight * 0.5) -
                          40 // Center vertically
                      : 50.0;

              return Positioned(
                top: topPosition,
                left: 16,
                right: 16,
                child: Transform.scale(
                  scale:
                      _isLocking
                          ? _lockScaleAnimation.value
                          : _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFAB40).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLocking
                              ? Icons.lock_outline
                              : (!_isInitialized
                                  ? Icons.face
                                  : _getEmotionIcon()),
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isLocking
                              ? "FED locked"
                              : (!_isInitialized
                                  ? "FED"
                                  : (_faceRect != null
                                      ? _emotion
                                      : "No face detected")),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom Control Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 40),
                      // Lock Button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFAB40),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFAB40).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _isLocking ? null : _handleLock,
                        ),
                      ),
                      // Camera Switch Button
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.cameraswitch_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _isLocking ? null : _switchCamera,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmotionIcon() {
    if (_emotion.toLowerCase().contains('happy')) {
      return Icons.sentiment_very_satisfied;
    } else if (_emotion.toLowerCase().contains('sad')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (_emotion.toLowerCase().contains('angry')) {
      return Icons.mood_bad;
    }
    return Icons.face;
  }
}

/// Model class for storing face detection data
class FaceData {
  final Rect rect;
  final String emotion;
  final int trackingId;

  FaceData({required this.rect, required this.emotion, this.trackingId = 0});
}

/// Custom painter for drawing face detection overlay
class FacePainter extends CustomPainter {
  final Rect faceRect;
  final Size previewSize;

  FacePainter({required this.faceRect, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFFFAB40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Calculate scaling factors
    final scaleX = size.width / previewSize.width;
    final scaleY = size.height / previewSize.height;

    // Draw face rectangle
    canvas.drawRect(
      Rect.fromLTRB(
        faceRect.left * scaleX,
        faceRect.top * scaleY,
        faceRect.right * scaleX,
        faceRect.bottom * scaleY,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faceRect != faceRect ||
        oldDelegate.previewSize != previewSize;
  }
}

/// Widget for creating emoji rain animation
class EmojiRain extends StatefulWidget {
  final String emotion;

  const EmojiRain({Key? key, required this.emotion}) : super(key: key);

  @override
  State<EmojiRain> createState() => _EmojiRainState();
}

class _EmojiRainState extends State<EmojiRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<EmojiParticle> particles = [];
  final Random random = Random();
  DateTime? _lastEmotionChange;
  static const Duration emotionUpdateDelay = Duration(milliseconds: 400);
  String _currentEmoji = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 60 FPS
    )..repeat();

    _createParticles();
  }

  void _createParticles() {
    particles.clear();
    _currentEmoji = _getEmojiForEmotion(widget.emotion);

    for (int i = 0; i < 50; i++) {
      particles.add(
        EmojiParticle(
          x: random.nextDouble() * 400,
          y: 800 + random.nextDouble() * 400,
          speed: 10 + random.nextDouble() * 15,
          emoji: _currentEmoji,
          size: 18 + random.nextDouble() * 10, // Reduced size range from 15-25
        ),
      );
    }
  }

  @override
  void didUpdateWidget(EmojiRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      final now = DateTime.now();
      if (_lastEmotionChange == null ||
          now.difference(_lastEmotionChange!) >= emotionUpdateDelay) {
        _lastEmotionChange = now;
        _createParticles(); // Create new particles when emotion changes
      }
    }
  }

  String _getEmojiForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
    }
    return ''; // Return empty for any other case
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var particle in particles) {
          particle.y -= particle.speed;
          particle.x += (random.nextDouble() - 0.5) * 6;

          if (particle.y < -50) {
            particle.y = 800 + random.nextDouble() * 400;
            particle.x = random.nextDouble() * 400;
            particle.speed = 10 + random.nextDouble() * 15;
            particle.size =
                18 + random.nextDouble() * 10; // Reduced size range from 15-25
          }
        }

        return CustomPaint(
          painter: EmojiRainPainter(particles),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Model class for emoji particles in the rain effect
class EmojiParticle {
  double x;
  double y;
  double speed;
  String emoji;
  double size;

  EmojiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.emoji,
    required this.size,
  });
}

/// Custom painter for the emoji rain animation
class EmojiRainPainter extends CustomPainter {
  final List<EmojiParticle> particles;

  EmojiRainPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.emoji,
          style: TextStyle(
            fontSize: particle.size,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(particle.x, particle.y));
    }
  }

  @override
  bool shouldRepaint(EmojiRainPainter oldDelegate) => true;
}
