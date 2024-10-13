import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_oauth/firebase_ui_oauth.dart' as fuo;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';

import 'google_client_id.dart'; // defines googleClientId property

class LoginInfo extends ChangeNotifier {
  LoginInfo._() : _user = FirebaseAuth.instance.currentUser;
  User? _user;
  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  static final _googleSignInProvider = GoogleProvider(
    // as per:
    // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/oauth.md#google-sign-in
    clientId: googleClientId,
  );

  static final List<fuo.OAuthProvider> authProviders = [
    _googleSignInProvider,
  ];

  static final instance = LoginInfo._();

  String? get displayName => user?.displayName;

  Future<void> logout() async {
    user = null;
    await FirebaseAuth.instance.signOut();

    // on mobile, the Google sign-in provider must be disconnected separately to
    // allow for a new account to be selected during login; otherwise the
    // account selected first will be used for all logins, even between sessions
    await _googleSignInProvider.provider.disconnect();
  }
}
