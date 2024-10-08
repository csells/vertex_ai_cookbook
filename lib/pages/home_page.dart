import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:go_router/go_router.dart';

import '../data/recipe_repository.dart';
import '../views/recipe_list_view.dart';
import '../views/recipe_response_view.dart';
import '../views/search_box.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _searchText = '';
  Future<bool>? _initRecipesFuture;

  final _provider = VertexProvider(
    // TODO: integrate RAG into the sample
    embeddingModel: FirebaseVertexAI.instance.generativeModel(
      model: 'text-embedding-004',
    ),
    chatModel: FirebaseVertexAI.instance.generativeModel(
      model: "gemini-1.5-flash",
      // TODO: add a drawer with configure for system instructions
      systemInstruction: Content.system(
        '''
You are a helpful assistant that generates recipes based on the ingredients and
instructions provided.

My food preferences are:
- I don't like mushrooms, tomatoes or cilantro.
- I love garlic and onions.
- I avoid milk, so I always replace that with oat milk.
- I try to keep carbs low, so I try to use appropriate substitutions.

When you generate a recipe, you should generate a JSON object with the following
structure:
{
  "title": "Recipe Title",
  "description": "Recipe Description",
  "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
  "instructions": ["Instruction 1", "Instruction 2", "Instruction 3"]
}

You should keep things casual and friendly. Feel free to mix rich text and JSON
output.
''',
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _initRecipesFuture = RecipeRepository.init().then((_) => true);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _initRecipesFuture,
        builder: (context, snapshot) => Scaffold(
          appBar: AppBar(
            title: const Text('Recipes'),
            actions: [
              IconButton(
                onPressed: snapshot.hasData ? _onAdd : null,
                tooltip: 'Add Recipe',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: snapshot.hasData
              ? _RowOrTabBar(
                  tabs: const [
                    Tab(text: 'Recipes'),
                    Tab(text: 'Chat'),
                  ],
                  children: [
                    Column(
                      children: [
                        SearchBox(onSearchChanged: _updateSearchText),
                        Expanded(
                            child: RecipeListView(searchText: _searchText)),
                      ],
                    ),
                    LlmChatView(
                      provider: _provider,
                      responseBuilder: (context, response) =>
                          RecipeResponseView(response),
                    ),
                  ],
                )
              : const Center(child: Text('Loading recipes...')),
        ),
      );

  void _updateSearchText(String text) => setState(() => _searchText = text);

  void _onAdd() => context.goNamed(
        'edit',
        pathParameters: {'recipe': RecipeRepository.newRecipeID},
      );
}

class _RowOrTabBar extends StatefulWidget {
  const _RowOrTabBar({required this.tabs, required this.children});
  final List<Widget> tabs;
  final List<Widget> children;

  @override
  State<_RowOrTabBar> createState() => _RowOrTabBarState();
}

class _RowOrTabBarState extends State<_RowOrTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) => MediaQuery.of(context).size.width > 600
      ? Row(
          children: [for (var child in widget.children) Expanded(child: child)],
        )
      : Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: widget.tabs,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.children,
              ),
            ),
          ],
        );
}
