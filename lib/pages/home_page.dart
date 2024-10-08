import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:go_router/go_router.dart';

import '../data/recipe_repository.dart';
import '../data/settings.dart';
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
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      systemInstruction: Content.system(
        '''
You are a helpful assistant that generates recipes based on the ingredients and 
instructions provided as well as my food preferences, which are as follows:
${Settings.foodPreferences.isEmpty ? 'I don\'t have any food preferences' : Settings.foodPreferences}

You should keep things casual and friendly. Feel free to mix in rich text
commentary with the recipes you generate. You may generate multiple recipes in
a single response, but only if asked. Generate each response in JSON format
with the following schema, including one or more "text" and "recipe" pairs as
well as any trailing text commentary you care to provide:

{
  "recipes": [
    {
      "text": "Any commentary you care to provide about the recipe.",
      "recipe":
      {
        "title": "Recipe Title",
        "description": "Recipe Description",
        "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
        "instructions": ["Instruction 1", "Instruction 2", "Instruction 3"]
      }
    }
  ],
  "text": "any final commentary you care to provide",
}
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
          drawer: Builder(builder: (context) {
            final controller = TextEditingController(
              text: Settings.foodPreferences,
            );
            return Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(child: Text('Food Preferences')),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter your food preferences...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OverflowBar(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          OutlinedButton(
                            child: const Text('Save'),
                            onPressed: () {
                              Settings.setFoodPreferences(controller.text);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
