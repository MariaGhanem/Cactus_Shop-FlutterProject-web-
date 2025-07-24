import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    // حذف macOS أو يمكنك كتابة:
    // case TargetPlatform.macOS:
    //   throw UnsupportedError('macOS not supported currently');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD0L9VXVmpqCUTEMyBJUI973x7s62d6e8s",
    authDomain: "cactus-shop-2025.firebaseapp.com",
    projectId: "cactus-shop-2025",
    storageBucket: "cactus-shop-2025.appspot.com",
    messagingSenderId: "173502754173",
    appId: "1:173502754173:web:32d112db05f65fe65ff014",
    measurementId: "G-TD8EGGWN1K",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD0L9VXVmpqCUTEMyBJUI973x7s62d6e8s",
    appId: "1:173502754173:android:80389d5775bb17535ff014",
    messagingSenderId: "173502754173",
    projectId: "cactus-shop-2025",
    storageBucket: "cactus-shop-2025.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyD0L9VXVmpqCUTEMyBJUI973x7s62d6e8s",
    appId: "1:173502754173:ios:edb6c0c02e805e755ff014", // عدل إلى App ID الصحيح أو اتركه كما هو إن لم تستخدم iOS
    messagingSenderId: "173502754173",
    projectId: "cactus-shop-2025",
    storageBucket: "cactus-shop-2025.appspot.com",
    iosBundleId: "com.example.cactusShop",
  );

/*
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyD0L9VXVmpqCUTEMyBJUI973x7s62d6e8s",
    appId: "1:173502754173:ios:<MACOS_APP_ID>", // ضع App ID الصحيح إذا توفر
    messagingSenderId: "173502754173",
    projectId: "cactus-shop-2025",
    storageBucket: "cactus-shop-2025.appspot.com",
    iosBundleId: "com.example.cactusShop",
  );
  */
}
