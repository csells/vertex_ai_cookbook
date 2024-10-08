import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

import 'recipe_data.dart';

class RecipeRepository {
  static const newRecipeID = '__NEW_RECIPE__';
  static const _defaultRecipesAsset = 'assets/recipes_default.json';

  static List<Recipe>? _recipes;
  static final items = ValueNotifier<Iterable<Recipe>>([]);

  // TODO: only access recipes from the currently logged in user
  static get _recipesCollection =>
      FirebaseFirestore.instance.collection('recipes');

  static Future<void> init() async {
    assert(_recipes == null, 'call RecipeRepository.init() exactly once');
    await _loadRecipes();
  }

  static Iterable<Recipe> get recipes {
    assert(_recipes != null, 'call RecipeRepository.init() exactly once');
    return _recipes!;
  }

  static Recipe getRecipe(String recipeId) {
    assert(_recipes != null, 'call RecipeRepository.init() exactly once');
    if (recipeId == newRecipeID) return Recipe.empty(newRecipeID);
    return _recipes!.singleWhere((r) => r.id == recipeId);
  }

  static Future<void> addNewRecipe(Recipe newRecipe) async {
    assert(_recipes != null, 'call RecipeRepository.init() exactly once');
    _recipes!.add(newRecipe);
    await _recipesCollection.doc(newRecipe.id).set(newRecipe.toJson());
    _notifyListeners();
  }

  static Future<void> updateRecipe(Recipe recipe) async {
    assert(_recipes != null, 'call RecipeRepository.init() exactly once');
    final i = _recipes!.indexWhere((r) => r.id == recipe.id);
    assert(i >= 0);
    _recipes![i] = recipe;
    await _recipesCollection.doc(recipe.id).update(recipe.toJson());
    _notifyListeners();
  }

  static Future<void> deleteRecipe(Recipe recipe) async {
    assert(_recipes != null, 'call RecipeRepository.init() exactly once');
    final removed = _recipes!.remove(recipe);
    assert(removed);
    await _recipesCollection.doc(recipe.id).delete();
    _notifyListeners();
  }

  static Future<void> _loadRecipes() async {
    final recipesCollection = _recipesCollection;
    final provider = VertexProvider(
      embeddingModel: FirebaseVertexAI.instance.generativeModel(
        model: 'text-embedding-004',
      ),
    );

    // Check if the collection exists and has documents
    final snapshot = await recipesCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // If the collection is empty, seed it with default recipes
      final contents = await rootBundle.loadString(_defaultRecipesAsset);
      final jsonList = json.decode(contents) as List;
      final defaultRecipes = <Recipe>[];
      for (var json in jsonList) {
        // TODO: remove all of the code that calculates the embedding
        // and updates the JSON; this is only to get the updated JSON
        // for default_recipes.json that includes the embedding data so
        // that it can be used for RAG searches -- once the embeddings
        // have been calculated, the default_recipes.json asset can be
        // replaced with the one augmented with the embeddings and they
        // don't have to be calculated again for the default recipes --
        // only for new and updated recipes, which happens one at a time.
        final title = json['title'];
        final description = json['description'];
        final ingredients = List<String>.from(json['ingredients']);
        final instructions = List<String>.from(json['instructions']);

        final s = Recipe.getEmbeddingString(
          title,
          description,
          ingredients,
          instructions,
        );

        final embedding = await provider.getDocumentEmbedding(s);

        json['embedding'] = embedding;
        defaultRecipes.add(Recipe.fromJson(json));
      }

      // Add default recipes to Firestore
      for (var recipe in defaultRecipes) {
        await recipesCollection.doc(recipe.id).set(recipe.toJson());
      }

      // dump the recipes to the console
      print(jsonEncode(defaultRecipes));

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
