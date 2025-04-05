/// Main entry point of the Face Emotion Detection (FED) application.
///
/// This file is responsible for:
/// - Initializing Flutter bindings
/// - Requesting camera permissions
/// - Setting up the app's theme and navigation
/// - Managing the app's routing system

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart';
import 'lock_screen.dart';
import 'MyHomePage.dart';

/// Initializes the application and sets up necessary permissions and cameras
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isDenied) return;

    // Initialize cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    runApp(MyApp(cameras: cameras));
  } catch (e) {
    print('Error initializing app: $e');
  }
}

/// Root widget of the application that sets up the theme and navigation
class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(cameras: cameras),
        '/home': (context) => MyHomePage(cameras: cameras),
        '/lock': (context) => LockScreen(cameras: cameras),
      },
    );
  }
}
