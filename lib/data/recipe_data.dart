import 'dart:convert';

import 'package:uuid/uuid.dart';

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.embedding,
    this.tags = const [],
    this.notes = '',
  });

  Recipe.empty(String id)
      : this(
          id: id,
          title: '',
          description: '',
          ingredients: [],
          instructions: [],
          embedding: [],
          tags: [],
          notes: '',
        );

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] ?? const Uuid().v4(),
        title: json['title'],
        description: json['description'],
        ingredients: List<String>.from(json['ingredients']),
        instructions: List<String>.from(json['instructions']),
        tags: json['tags'] == null ? [] : List<String>.from(json['tags']),
        notes: json['notes'] ?? '',
        embedding: List<double>.from(json['embedding']),
      );

  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String notes;
  final List<double> embedding;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': tags,
        'notes': notes,
      };

  static List<Recipe> loadFrom(String json) {
    final jsonList = jsonDecode(json) as List;
    return [for (final json in jsonList) Recipe.fromJson(json)];
  }

  static String getEmbeddingString(
    String title,
    String description,
    List<String> ingredients,
    List<String> instructions,
  ) =>
      '''# $title
$description

## Ingredients
${ingredients.join('\n')}

## Instructions
${instructions.join('\n')}
''';
}
