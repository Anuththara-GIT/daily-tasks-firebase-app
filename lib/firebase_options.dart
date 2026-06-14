import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCqv1-Jxxrl7HFV_TtwOs1UCkaeyDDkcRE',
    appId: '1:881152446197:web:2d95eeef5546a5e6b67fbc',
    messagingSenderId: '881152446197',
    projectId: 'to-do-ca1fa',
    authDomain: 'to-do-ca1fa.firebaseapp.com',
    storageBucket: 'to-do-ca1fa.firebasestorage.app',
    measurementId: 'G-K6MMBCQZ09',
  );
}
