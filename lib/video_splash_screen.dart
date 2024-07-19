import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '/main.dart';

/// The main function of the application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
///
/// This widget builds the MaterialApp and uses a FutureBuilder to determine
/// whether to display the VideoSplashScreen or the NextScreen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: checkIfFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            if (snapshot.data == true) {
              return const VideoSplashScreen();
            } else {
              return const NextScreen();
            }
          }
        },
      ),
    );
  }

  /// Checks if it's the first time the app is being launched.
  ///
  /// This function retrieves the 'hasWatchedVideo' value from SharedPreferences.
  /// If the value is null or false, it sets the value to true and returns true.
  /// If the value is true, it returns false.
  ///
  /// @return A Future that completes with a boolean indicating whether it's the
  /// first time the app is being launched.
  Future<bool> checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('hasWatchedVideo');

    if (isFirstTime == null || isFirstTime == false) {
      await prefs.setBool('hasWatchedVideo', true);
      return true;
    } else {
      return false;
    }
  }
}

/// A widget that displays a video splash screen.
///
/// This widget initializes a VideoPlayerController and plays a video when the
/// widget is first created. When the video finishes playing, it navigates to
/// the SignInSignUpPage.
class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  VideoSplashScreenState createState() => VideoSplashScreenState();
}

class VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(false);
        _controller.addListener(checkVideo);
        setState(() {});
      });
  }

  /// Checks if the video is playing and navigates to the SignInSignUpPage when
  /// the video finishes playing.
  ///
  /// This function is added as a listener to the VideoPlayerController. It
  /// checks if the video is playing and if it's not, it waits for the duration
  /// of the video and then navigates to the SignInSignUpPage.
  ///
  /// The navigation is wrapped in a Future.delayed function to wait for the
  /// length of the video before navigating. This ensures that the video has
  /// enough time to play completely.
  ///
  /// Before navigating, it checks if the State object is still mounted. This
  /// prevents an error that can occur if the widget is unmounted before the
  /// navigation occurs
  void checkVideo() {
    // Check if the video is not playing and if the position is at t1he end
    if (!_controller.value.isPlaying &&
        _controller.value.position == _controller.value.duration) {
      if (mounted) {
        // Navigate to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInSignUpPage()),
        );
      }
    }
  }

  /// Builds the widget tree for the VideoSplashScreen.
  ///
  /// This method returns a Scaffold widget that contains a Stack. The Stack
  /// contains a Center widget, which in turn contains either an AspectRatio
  /// widget or a Container, depending on whether the VideoPlayerController
  /// has been initialized.
  ///
  /// If the VideoPlayerController is initialized, the AspectRatio widget is
  /// used to maintain the aspect ratio of the video. The AspectRatio's child
  /// is a VideoPlayer widget that plays the video.
  ///
  /// If the VideoPlayerController is not initialized, an empty Container
  /// widget is displayed.
  ///
  /// @override
  /// @param context The build context.
  /// @return A widget that either displays the video or an empty container.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

 /// Disposes the VideoPlayerController when the widget is removed from the
 /// widget tree.
 /// Dispose method of a State object in Flutter. Here’s what it does:
 /// dispose is a lifecycle method in Flutter that is called when this State object will never build again.
 /// Once the framework calls dispose, you cannot call setState.
 /// 
 /// super.dispose(); is calling the same dispose method in the superclass to make sure
 /// everything from the superclass also gets disposed properly.
 /// 
 /// _controller.dispose(); is disposing the VideoPlayerController object. Disposing an object
 /// is essentially freeing up the resources that the object was using. The VideoPlayerController is likely holding
 /// onto some system resources (like video or audio codecs) that are needed to play videos. When application is
 /// done with the VideoPlayerController, it call dispose to free up these resources so they can be used by something else.

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

/// A widget that displays the main screen of the application.
class NextScreen extends StatelessWidget {
  const NextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Main Screen'),
      ),
    );
  }
}
