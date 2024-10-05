import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/recipe_repository.dart';
import 'firebase_options.dart';
import 'pages/edit_recipe_page.dart';
import 'pages/home_page.dart';

// https://firebase.google.com/docs/flutter/setup

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(App());
}

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
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}
