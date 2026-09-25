import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // Get these values directly from your Firebase Console Project Settings
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB9jisTKkVRitHQxnm7oj1ez8G8SCz7WTU",
    appId: "1:509998612404:web:5d6b985fe2bdc8829b7ce1",
    messagingSenderId: "509998612404",
    projectId: "farming-almanac",
    authDomain: "farming-almanac.firebaseapp.com",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDQ3BCh70YQyYsoVdoed1dTCLFv7XTpo0A",
    appId: "1:509998612404:android:b10a3d0b128a9fe49b7ce1",
    messagingSenderId: '509998612404',
    projectId: "farming-almanac",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.example.yourApp',
  );
}