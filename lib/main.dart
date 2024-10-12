import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import 'data/recipe_repository.dart';
import 'data/settings.dart';
import 'firebase_options.dart'; // from https://firebase.google.com/docs/flutter/setup
import 'pages/edit_recipe_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(App());
}

class App extends StatefulWidget {
  App({super.key}) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      App.currentUser.value = user;
      RecipeRepository.setCurrentUser(user);
    });
  }

  static final currentUser =
      ValueNotifier<User?>(FirebaseAuth.instance.currentUser);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit/:recipe',
            builder: (context, state) => EditRecipePage(
              recipeId: state.pathParameters['recipe']!,
            ),
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => SignInScreen(
          showAuthActionSwitch: false,
          breakpoint: 600,
          providers: [
            GoogleProvider(
              clientId: _googleClientIdFrom(
                DefaultFirebaseOptions.currentPlatform,
              ),
            ),
          ],
        ),
      ),
    ],
    redirect: (context, state) {
      final loginLocation = state.namedLocation('login');
      final homeLocation = state.namedLocation('home');
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation == loginLocation;

      if (!loggedIn && !loggingIn) return loginLocation;
      if (loggedIn && loggingIn) return homeLocation;
      return null;
    },
    refreshListenable: App.currentUser,
  );

  // inspired by https://github.com/firebase/FirebaseUI-Flutter/blob/main/packages/firebase_ui_auth/example/lib/config.dart
  static String _googleClientIdFrom(FirebaseOptions options) =>
      switch (currentUniversalPlatform) {
        UniversalPlatformType.MacOS ||
        UniversalPlatformType.IOS =>
          options.iosClientId!,
        _ => options.androidClientId!,
      };

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}
