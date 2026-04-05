import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:fortress/Features/Response%20Screen/emergencies_screen.dart';
import 'package:fortress/Features/User/Screens/LiveStreaming/live_stream.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'Common Widgets/Onboarding.dart';
import 'Features/User/Screens/SignUp/verify_email_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    
    // Check for "id" in URL (for web viewers)
    String? liveId = Uri.base.queryParameters['id'];

    if (liveId != null && liveId.isNotEmpty) {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fortrace Viewer',
        home: LiveStreamingPage(isHost: false, liveId: liveId),
      );
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fortrace',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: user == null ? const OnBoardingScreen() : const VerifyEmailPage(),
    );
  }
}
