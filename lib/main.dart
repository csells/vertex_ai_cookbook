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
  // FirebaseUIAuth.configureProviders([
  //   GoogleProvider(clientId: _googleClientIdFrom(firebaseOptions)),
  // ]);

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

class App extends StatefulWidget {
  App({super.key}) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('authStateChanges: $user');
      if (user == null) App.repo.value = null;
    });
  }

  static final repo = ValueNotifier<RecipeRepository?>(null);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) {
          assert(App.repo.value != null);
          return HomePage(repository: App.repo.value!);
        },
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit/:recipe',
            builder: (context, state) {
              assert(App.repo.value != null);
              return EditRecipePage(
                repository: App.repo.value!,
                recipeId: state.pathParameters['recipe']!,
              );
            },
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) {
          assert(App.repo.value == null);
          return SignInScreen(
            providers: [
              GoogleProvider(
                clientId: _googleClientIdFrom(
                  DefaultFirebaseOptions.currentPlatform,
                ),
              ),
            ],
            actions: [
              AuthStateChangeAction<SignedIn>(
                (context, state) {
                  debugPrint('User signed in: ${state.user?.uid}');
                  context.goNamed('loading');
                },
              ),
            ],
          );
        },
      ),
      GoRoute(
        name: 'loading',
        path: '/loading',
        builder: (context, state) {
          assert(App.repo.value == null);
          return _LoadingPage(
            onRecipesLoaded: (repo) => App.repo.value = repo,
          );
        },
      ),
    ],
    redirect: (context, state) {
      debugPrint('redirect: ${state.matchedLocation}');
      final loginLocation = state.namedLocation('login');
      final loadingLocation = state.namedLocation('loading');
      final homeLocation = state.namedLocation('home');
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation == loginLocation;
      final loaded = App.repo.value != null;
      final loading = state.matchedLocation == loadingLocation;

      if (!loggedIn) return !loggingIn ? loginLocation : null;
      if (!loaded) return !loading ? loadingLocation : null;
      if (loaded && loading) return homeLocation;
      return null;
    },
    refreshListenable: App.repo,
    debugLogDiagnostics: true,
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.onRecipesLoaded});
  final void Function(RecipeRepository repo) onRecipesLoaded;

  @override
  Widget build(BuildContext context) => FutureBuilder<RecipeRepository>(
        future: RecipeRepository.getUserRepository(
                FirebaseAuth.instance.currentUser!)
            .then((repo) {
          onRecipesLoaded(repo);
          return repo;
        }),
        builder: (context, snapshot) => Scaffold(
          appBar: AppBar(title: const Text('Recipes')),
          body: snapshot.hasError
              ? Center(child: Text(snapshot.error.toString()))
              : snapshot.hasData
                  ? const Center(child: Text('Recipes Loaded'))
                  : const Center(child: Text('Loading recipes...')),
        ),
      );
}
