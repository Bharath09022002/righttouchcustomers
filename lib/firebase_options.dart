// File generated for RightTouch Firebase configuration based on google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCroqPzTBPfDHoMyUDw3DNUkR_BvVIvK98',
    appId: '1:1004708226378:android:39dfae6aa9bb4b1648cdb3',
    messagingSenderId: '1004708226378',
    projectId: 'righttouchmessaging-401e9',
    storageBucket: 'righttouchmessaging-401e9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCroqPzTBPfDHoMyUDw3DNUkR_BvVIvK98',
    appId: '1:1004708226378:ios:placeholder',
    messagingSenderId: '1004708226378',
    projectId: 'righttouchmessaging-401e9',
    storageBucket: 'righttouchmessaging-401e9.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCroqPzTBPfDHoMyUDw3DNUkR_BvVIvK98',
    appId: '1:1004708226378:web:placeholder',
    messagingSenderId: '1004708226378',
    projectId: 'righttouchmessaging-401e9',
    storageBucket: 'righttouchmessaging-401e9.firebasestorage.app',
  );
}
