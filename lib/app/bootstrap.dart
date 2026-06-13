import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:dealsouk/firebase_options.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
