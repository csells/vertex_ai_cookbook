import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'recipe_data.dart';

class RecipeRepository extends ChangeNotifier {
  RecipeRepository._({
    required CollectionReference collection,
    required List<Recipe> recipes,
  })  : _recipesCollection = collection,
        _recipes = recipes;

  final CollectionReference _recipesCollection;
  final List<Recipe> _recipes;

  static const newRecipeID = '__NEW_RECIPE__';
  static const _defaultRecipesAsset = 'assets/recipes_default.json';

  static User? _currentUser;
  static RecipeRepository? _currentUserRepository;

  static bool get hasCurrentUser => _currentUser != null;
  static Future<RecipeRepository> get forCurrentUser async {
    // no user, no repository
    if (_currentUser == null) throw Exception('No user logged in');

    // load the repository for the current user if it's not already loaded
    if (_currentUserRepository == null) {
      assert(_currentUser != null);
      final collection = FirebaseFirestore.instance
          .collection('users/${_currentUser!.uid}/recipes');
      final recipes = await RecipeRepository._loadRecipes(collection);
      _currentUserRepository = RecipeRepository._(
        collection: collection,
        recipes: recipes,
      );
    }

    return _currentUserRepository!;
  }

  static void setCurrentUser(User? user) {
    // clear the repository cache when the user is logged out
    if (user == null) {
      _currentUser = null;
      _currentUserRepository = null;
      return;
    }

    // ignore if the same user is already logged in
    if (user.uid == _currentUser?.uid) return;

    // clear the repository cache to load the user's recipes on demand
    _currentUser = user;
    _currentUserRepository = null;
  }

  static Future<List<Recipe>> _loadRecipes(
    CollectionReference collection,
  ) async {
    // Check if the collection exists and has documents
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // If the collection is empty, seed it with default recipes
      final contents = await rootBundle.loadString(_defaultRecipesAsset);
      final jsonList = json.decode(contents) as List;
      final defaultRecipes =
          jsonList.map((json) => Recipe.fromJson(json)).toList();

      // Add default recipes to Firestore
      for (var recipe in defaultRecipes) {
        await collection.doc(recipe.id).set(recipe.toJson());
      }

      return defaultRecipes;
    }

    // If the collection exists and has documents, fetch all recipes
    final querySnapshot = await collection.get();
    final recipes = <Recipe>[];
    for (var doc in querySnapshot.docs) {
      recipes.add(Recipe.fromJson(doc.data() as Map<String, dynamic>));
    }

    return recipes;
  }

  Iterable<Recipe> get recipes => _recipes;

  Recipe getRecipe(String recipeId) => (recipeId == newRecipeID)
      ? Recipe.empty(newRecipeID)
      : _recipes.singleWhere((r) => r.id == recipeId);

  Future<void> addNewRecipe(Recipe newRecipe) async {
    _recipes.add(newRecipe);
    await _recipesCollection.doc(newRecipe.id).set(newRecipe.toJson());
    notifyListeners();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final i = _recipes.indexWhere((r) => r.id == recipe.id);
    assert(i >= 0);
    _recipes[i] = recipe;
    await _recipesCollection.doc(recipe.id).update(recipe.toJson());
    notifyListeners();
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final removed = _recipes.remove(recipe);
    assert(removed);
    await _recipesCollection.doc(recipe.id).delete();
    notifyListeners();
  }
}
