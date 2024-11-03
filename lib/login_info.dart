import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fua;
import 'package:flutter/foundation.dart';

class LoginInfo extends ChangeNotifier {
  LoginInfo._() : _user = FirebaseAuth.instance.currentUser;
  User? _user;
  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  static final List<fua.AuthProvider> authProviders = [
    fua.EmailAuthProvider(),
  ];

  static final instance = LoginInfo._();

  String? get displayName => user?.displayName ?? user?.email;

  Future<void> logout() async {
    user = null;
    await FirebaseAuth.instance.signOut();
  }
}
