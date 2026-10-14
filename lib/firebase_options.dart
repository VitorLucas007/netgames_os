import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opções do Firebase lidas do arquivo `.env` (que não vai para o git).
///
/// O valor entra na compilação com `--dart-define-from-file=.env`.
/// Sem essa flag, os valores ficam vazios e o app avisa o que fazer.
/// Se rodar `flutterfire configure` de novo, este arquivo é sobrescrito:
/// restaure-o pelo git e atualize o `.env` com as chaves novas.
class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static FirebaseOptions get currentPlatform {
    if (_projectId.isEmpty) {
      throw StateError(
        'Chaves do Firebase não encontradas. Crie o arquivo .env (modelo em .env.example) '
        'e rode com --dart-define-from-file=.env',
      );
    }
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('Firebase não configurado para esta plataforma.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _bucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
    iosBundleId: _iosBundleId,
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WINDOWS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WINDOWS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _bucket,
  );
}
