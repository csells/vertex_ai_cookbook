import 'dart:convert';

import 'package:uuid/uuid.dart';

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
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
      );

  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': tags,
        'notes': notes,
      };

  static Future<List<Recipe>> loadFrom(String json) async {
    final jsonList = jsonDecode(json) as List;
    return [for (final json in jsonList) Recipe.fromJson(json)];
  }

  @override
  String toString() => '''
# $title
$description

## Ingredients
${ingredients.join('\n')}

## Instructions
${instructions.join('\n')}
''';
}
