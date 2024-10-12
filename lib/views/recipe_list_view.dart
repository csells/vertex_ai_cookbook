// NOTE: 240826: Now sorting recipe list by title

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/recipe_data.dart';
import '../data/recipe_repository.dart';
import 'recipe_view.dart';

class RecipeListView extends StatefulWidget {
  const RecipeListView({
    super.key,
    required this.repository,
    required this.searchText,
  });

  final RecipeRepository repository;
  final String searchText;

  @override
  _RecipeListViewState createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<RecipeListView> {
  final _expanded = <String, bool>{};

  Iterable<Recipe> _filteredRecipes(Iterable<Recipe> recipes) => recipes
      .where((recipe) =>
          recipe.title
              .toLowerCase()
              .contains(widget.searchText.toLowerCase()) ||
          recipe.description
              .toLowerCase()
              .contains(widget.searchText.toLowerCase()) ||
          recipe.tags.any((tag) =>
              tag.toLowerCase().contains(widget.searchText.toLowerCase())))
      .toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.repository,
        builder: (context, child) => ListView(
          children: [
            for (final recipe in _filteredRecipes(widget.repository.recipes))
              RecipeView(
                key: ValueKey(recipe.id),
                recipe: recipe,
                expanded: _expanded[recipe.id] == true,
                onExpansionChanged: (expanded) =>
                    _onExpand(recipe.id, expanded),
                onEdit: () => _onEdit(recipe),
                onDelete: () async => await _onDelete(recipe),
              ),
          ],
        ),
      );

  void _onExpand(String recipeId, bool expanded) =>
      _expanded[recipeId] = expanded;

  void _onEdit(Recipe recipe) => context.goNamed(
        'edit',
        pathParameters: {'recipe': recipe.id},
      );

  Future<void> _onDelete(Recipe recipe) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text(
          'Are you sure you want to delete the recipe "${recipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await widget.repository.deleteRecipe(recipe);
    }
  }
}
