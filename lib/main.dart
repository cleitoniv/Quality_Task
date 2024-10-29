import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:quality_task/module/auth/Authenticate_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(const QualityTask());
    });
    
}

class QualityTask extends StatelessWidget {
  const QualityTask({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthenticateScreen(),
    );
  }
}
