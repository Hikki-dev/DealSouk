// FAKE values for demo mode, copied to lib/firebase_options.dart by demo/prepare.sh.
// They point at the local Firebase emulators. Never use them with a real project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:demo',
    messagingSenderId: '000000000000',
    projectId: 'demo-dealsouk',
    authDomain: 'demo-dealsouk.firebaseapp.com',
    storageBucket: 'demo-dealsouk.appspot.com',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:demo',
    messagingSenderId: '000000000000',
    projectId: 'demo-dealsouk',
    storageBucket: 'demo-dealsouk.appspot.com',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:demo',
    messagingSenderId: '000000000000',
    projectId: 'demo-dealsouk',
    storageBucket: 'demo-dealsouk.appspot.com',
    iosBundleId: 'com.example.dealsouk',
  );
}
