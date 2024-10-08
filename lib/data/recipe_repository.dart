import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'recipe_data.dart';

class RecipeRepository {
  static const newRecipeID = '__NEW_RECIPE__';
  static const _assetFileName = 'assets/recipes_default.json';

  static List<Recipe>? _recipes;
  static final items = ValueNotifier<Iterable<Recipe>>([]);

  // TODO: only access recipes from the currently logged in user
  static get _recipesCollection =>
      FirebaseFirestore.instance.collection('recipes');

  static Future<void> init() async {
    assert(_recipes == null, 'call init() only once');
    await _loadRecipes();
  }

  static Iterable<Recipe> get recipes {
    assert(_recipes != null, 'call init() first');
    return _recipes!;
  }

  static Recipe getRecipe(String recipeId) {
    assert(_recipes != null, 'call init() first');
    if (recipeId == newRecipeID) return Recipe.empty(newRecipeID);
    return _recipes!.singleWhere((r) => r.id == recipeId);
  }

  static Future<void> addNewRecipe(Recipe newRecipe) async {
    assert(_recipes != null, 'call init() first');
    _recipes!.add(newRecipe);
    await _recipesCollection.doc(newRecipe.id).set(newRecipe.toJson());
    _notifyListeners();
  }

  static Future<void> updateRecipe(Recipe recipe) async {
    assert(_recipes != null, 'call init() first');
    final i = _recipes!.indexWhere((r) => r.id == recipe.id);
    assert(i >= 0);
    _recipes![i] = recipe;
    await _recipesCollection.doc(recipe.id).update(recipe.toJson());
    _notifyListeners();
  }

  static Future<void> deleteRecipe(Recipe recipe) async {
    assert(_recipes != null, 'call init() first');
    final removed = _recipes!.remove(recipe);
    assert(removed);
    await _recipesCollection.doc(recipe.id).delete();
    _notifyListeners();
  }

  static Future<void> _loadRecipes() async {
    final recipesCollection = _recipesCollection;

    // Check if the collection exists and has documents
    final snapshot = await recipesCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // If the collection is empty, seed it with default recipes
      final contents = await rootBundle.loadString(_assetFileName);
      final jsonList = json.decode(contents) as List;
      final defaultRecipes =
          jsonList.map((json) => Recipe.fromJson(json)).toList();

      // Add default recipes to Firestore
      for (var recipe in defaultRecipes) {
        await recipesCollection.doc(recipe.id).set(recipe.toJson());
      }

      _recipes = defaultRecipes;
    } else {
      // If the collection exists and has documents, fetch all recipes
      final querySnapshot = await recipesCollection.get();
      final recipes = <Recipe>[];
      for (var doc in querySnapshot.docs) {
        recipes.add(Recipe.fromJson(doc.data()));
      }

      _recipes = recipes;
    }

    _notifyListeners();
  }

  static void _notifyListeners() {
    assert(_recipes != null);
    items.value = [];
    items.value = _recipes!;
  }
}
