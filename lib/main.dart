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

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);
  FirebaseUIAuth.configureProviders([
    GoogleProvider(clientId: _googleClientIdFrom(firebaseOptions)),
  ]);

  runApp(App());
}

// inspired by https://github.com/firebase/FirebaseUI-Flutter/blob/main/packages/firebase_ui_auth/example/lib/config.dart
String _googleClientIdFrom(FirebaseOptions options) =>
    switch (currentUniversalPlatform) {
      UniversalPlatformType.MacOS ||
      UniversalPlatformType.IOS =>
        options.iosClientId!,
      _ => options.androidClientId!,
    };

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (BuildContext context, _) => const HomePage(),
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit/:recipe',
            builder: (context, state) {
              final recipeId = state.pathParameters['recipe']!;
              final recipe = RecipeRepository.getRecipe(recipeId);
              return EditRecipePage(recipe: recipe);
            },
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (BuildContext context, _) => SignInScreen(
          actions: [
            AuthStateChangeAction<SignedIn>(
              (context, state) => context.goNamed('home'),
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
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}
