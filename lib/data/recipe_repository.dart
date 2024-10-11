import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'recipe_data.dart';

// TODO: only access recipes from the currently logged in user
class RecipeRepository {
  RecipeRepository._(this._recipesCollection);
  final CollectionReference _recipesCollection;

  static Future<RecipeRepository> getUserRepository(User user) async {
    final recipesCollection =
        FirebaseFirestore.instance.collection('users/${user.uid}/recipes');
    final repo = RecipeRepository._(recipesCollection);
    await repo._loadRecipes();
    return repo;
  }

  static const newRecipeID = '__NEW_RECIPE__';
  static const _defaultRecipesAsset = 'assets/recipes_default.json';

  late List<Recipe> _recipes;
  final items = ValueNotifier<Iterable<Recipe>>([]);
  Iterable<Recipe> get recipes => items.value;

  Recipe getRecipe(String recipeId) => (recipeId == newRecipeID)
      ? Recipe.empty(newRecipeID)
      : _recipes.singleWhere((r) => r.id == recipeId);

  Future<void> addNewRecipe(Recipe newRecipe) async {
    _recipes.add(newRecipe);
    await _recipesCollection.doc(newRecipe.id).set(newRecipe.toJson());
    _notifyListeners();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final i = _recipes.indexWhere((r) => r.id == recipe.id);
    assert(i >= 0);
    _recipes[i] = recipe;
    await _recipesCollection.doc(recipe.id).update(recipe.toJson());
    _notifyListeners();
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final removed = _recipes.remove(recipe);
    assert(removed);
    await _recipesCollection.doc(recipe.id).delete();
    _notifyListeners();
  }

  Future<void> _loadRecipes() async {
    // Check if the collection exists and has documents
    final snapshot = await _recipesCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // If the collection is empty, seed it with default recipes
      final contents = await rootBundle.loadString(_defaultRecipesAsset);
      final jsonList = json.decode(contents) as List;
      final defaultRecipes =
          jsonList.map((json) => Recipe.fromJson(json)).toList();

      // Add default recipes to Firestore
      for (var recipe in defaultRecipes) {
        await _recipesCollection.doc(recipe.id).set(recipe.toJson());
      }

      _recipes = defaultRecipes;
    } else {
      // If the collection exists and has documents, fetch all recipes
      final querySnapshot = await _recipesCollection.get();
      final recipes = <Recipe>[];
      for (var doc in querySnapshot.docs) {
        recipes.add(Recipe.fromJson(doc.data() as Map<String, dynamic>));
      }

      _recipes = recipes;
    }

    _notifyListeners();
  }

  void _notifyListeners() {
    items.value = [];
    items.value = _recipes;
  }
}
