import 'dart:convert';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../data/recipe_data.dart';
import '../data/recipe_repository.dart';
import '../data/settings.dart';

class EditRecipePage extends StatefulWidget {
  const EditRecipePage({required this.recipeId, super.key});
  final String recipeId;

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();

  final _provider = VertexProvider(
    generativeModel: FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema(
          SchemaType.object,
          properties: {
            'modifications': Schema(
              description: 'The modifications to the recipe you made',
              SchemaType.string,
            ),
            'recipe': Schema(
              SchemaType.object,
              properties: {
                'title': Schema(SchemaType.string),
                'description': Schema(SchemaType.string),
                'ingredients': Schema(
                  SchemaType.array,
                  items: Schema(SchemaType.string),
                ),
                'instructions': Schema(
                  SchemaType.array,
                  items: Schema(SchemaType.string),
                ),
              },
            ),
          },
        ),
      ),
      systemInstruction: Content.system(
        '''
You are a helpful assistant that generates recipes based on the ingredients and 
instructions provided as well as my food preferences, which are as follows:
${Settings.foodPreferences.isEmpty ? 'I don\'t have any food preferences' : Settings.foodPreferences}

Generate a response in JSON format with the following schema:
{
  "modifications": "The modifications to the recipe you made",
  "recipe": {
    "title": "Recipe Title",
    "description": "Recipe Description",
    "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
    "instructions": ["Instruction 1", "Instruction 2", "Instruction 3"]
  }
}
''',
      ),
    ),
  );

  late final _recipeFuture = Future<Recipe>(() async {
    final repository = await RecipeRepository.forCurrentUser;
    final recipe = repository.getRecipe(widget.recipeId);
    _titleController.text = recipe.title;
    _descriptionController.text = recipe.description;
    _ingredientsController.text = recipe.ingredients.join('\n');
    _instructionsController.text = recipe.instructions.join('\n');
    return recipe;
  });

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  bool get _isNewRecipe => widget.recipeId == RecipeRepository.newRecipeID;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${_isNewRecipe ? 'Add' : 'Edit'} Recipe'),
        ),
        body: FutureBuilderEx<Recipe>(
          future: _recipeFuture,
          builder: (context, recipe) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a name for your recipe...',
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Recipe title is requires'
                        : null,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'In a few words, describe your recipe...',
                    ),
                    maxLines: null,
                  ),
                  TextField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients🍎 (one per line)',
                      hintText: 'e.g., 2 cups flour\n1 tsp salt\n1 cup sugar',
                    ),
                    maxLines: null,
                  ),
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions🥧 (one per line)',
                      hintText: 'e.g., Mix ingredients\nBake for 30 minutes',
                    ),
                    maxLines: null,
                  ),
                  const Gap(16),
                  OverflowBar(
                    spacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () async => await _onMagic(),
                        child: const Text('Magic'),
                      ),
                      OutlinedButton(
                        onPressed: () async => await _onSave(),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final recipe = Recipe(
      id: _isNewRecipe ? const Uuid().v4() : widget.recipeId,
      title: _titleController.text,
      description: _descriptionController.text,
      ingredients: _ingredientsController.text.split('\n'),
      instructions: _instructionsController.text.split('\n'),
    );

    final repository = await RecipeRepository.forCurrentUser;
    if (_isNewRecipe) {
      repository.addNewRecipe(recipe);
    } else {
      repository.updateRecipe(recipe);
    }

    // ignore: use_build_context_synchronously
    if (context.mounted) context.goNamed('home');
  }

  Future<void> _onMagic() async {
    final stream = _provider.sendMessageStream(
      'Generate a modified version of this recipe based on my food preferences: '
      '${_ingredientsController.text}\n\n${_instructionsController.text}',
    );

    try {
      final response = await stream.join();
      final json = jsonDecode(response);
      final modifications = json['modifications'];
      final recipe = Recipe.fromJson(json['recipe']);

      if (!context.mounted) return;
      final accept = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: Text(recipe.title),
          content: SizedBox(
            height: 200,
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modifications:'),
                const Gap(16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(modifications),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (accept == true) {
        setState(() {
          _titleController.text = recipe.title;
          _descriptionController.text = recipe.description;
          _ingredientsController.text = recipe.ingredients.join('\n');
          _instructionsController.text = recipe.instructions.join('\n');
        });
      }
    } catch (ex) {
      if (context.mounted) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(ex.toString()),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
