# Face Emotion Detection (FED) App

A Flutter application that detects faces and analyzes emotions in real-time using the device's camera.

## Project Structure

### Main Files

1. `lib/main.dart`
   - Entry point of the application
   - Handles app initialization and routing
   - Sets up theme and navigation

2. `lib/splash_screen.dart`
   - Displays the initial splash screen
   - Shows app logo and name
   - Handles transition to main screen

3. `lib/MyHomePage.dart`
   - Main screen of the application
   - Contains camera preview and face detection
   - Implements emotion analysis
   - Shows emoji rain effects

4. `lib/lock_screen.dart`
   - Security screen for the application
   - Handles app locking functionality

### Core Features

1. Camera Integration
   - Real-time camera preview
   - Front and back camera support
   - Proper orientation handling
   - Camera permission management

2. Face Detection
   - Real-time face detection using Google ML Kit
   - Face tracking and bounding box display
   - Multiple face detection support

3. Emotion Analysis
   - Detects three main emotions:
     - Happy 😊
     - Sad 😢
     - Angry 😠
   - Emotion-specific visual feedback
   - Real-time emotion updates

4. Visual Effects
   - Emoji rain animation
   - Emotion-specific particle effects
   - Smooth transitions and animations
   - Custom face overlay painting

### Key Components

1. `FaceData` Model
   - Stores face detection results
   - Contains bounding box coordinates
   - Tracks face ID and emotions

2. `EmojiRain` Widget
   - Creates particle effects
   - Emotion-specific animations
   - Custom particle behavior

3. `FacePainter` CustomPainter
   - Draws face detection overlay
   - Shows bounding boxes
   - Displays emotion indicators

### Technical Details

1. Dependencies
   - camera: ^0.10.5+9
   - google_mlkit_face_detection: ^0.9.0
   - permission_handler: ^11.1.0

2. Platform Support
   - Works on both iOS and Android
   - Handles platform-specific permissions
   - Adapts to different screen sizes

3. Performance Optimizations
   - Efficient face detection processing
   - Optimized animation rendering
   - Memory management for camera usage

### Usage

1. Launch the app
2. Grant camera permissions
3. Point camera at faces
4. View real-time emotion detection
5. See emotion-specific effects

### Setup Instructions

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Requirements

- Flutter SDK
- Android Studio / Xcode
- Physical device or emulator with camera
- Internet connection for initial setup

### Notes

- App requires camera permissions
- Works best with well-lit environments
- Performance may vary based on device capabilities
