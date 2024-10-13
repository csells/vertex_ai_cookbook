import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_oauth/firebase_ui_oauth.dart' as fuo;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

import 'firebase_options.dart';

class LoginInfo extends ChangeNotifier {
  LoginInfo._() : _user = FirebaseAuth.instance.currentUser;

  User? _user;

  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  static final _googleSignInProvider = GoogleProvider(
    clientId: _googleClientIdFrom(
      DefaultFirebaseOptions.currentPlatform,
    ),
  );

  static final List<fuo.OAuthProvider> authProviders = [
    _googleSignInProvider,
  ];

  static final instance = LoginInfo._();

  String? get displayName => user?.displayName;

  Future<void> logout() async {
    user = null;
    await FirebaseAuth.instance.signOut();

    // on mobile, the Google sign-in provider must be disconnected separately
    // to allow for a new account to be selected during login; otherwise the
    // account selected first will be used for all logins
    await _googleSignInProvider.provider.signOut();
  }

  // inspired by https://github.com/firebase/FirebaseUI-Flutter/blob/main/packages/firebase_ui_auth/example/lib/config.dart
  static String _googleClientIdFrom(FirebaseOptions options) =>
      switch (currentUniversalPlatform) {
        UniversalPlatformType.MacOS ||
        UniversalPlatformType.IOS =>
          options.iosClientId!,
        UniversalPlatformType.Android => '', // it's ignored on Android
        _ => throw UnsupportedError(
            'Unsupported platform: $currentUniversalPlatform',
          ),
      };
}
