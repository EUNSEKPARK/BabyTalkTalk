// firebase_options.dart
// TODO: flutterfire configure 명령어로 실제 Firebase 프로젝트 설정을 생성하세요.
// 현재는 빌드용 placeholder입니다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMJGu0tthkD-He4wvd2y4Vl2c7fbzKb5c',
    appId: '1:606442478276:android:e14ea7a16de64dfb934791',
    messagingSenderId: '606442478276',
    projectId: 'chat-baby-time',
    storageBucket: 'chat-baby-time.firebasestorage.app',
  );

  // TODO: 실제 Firebase 프로젝트 값으로 교체하세요

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'chat-baby-time',
    iosBundleId: 'com.chatbabytime.app',
    storageBucket: 'chat-baby-time.appspot.com',
  );
}