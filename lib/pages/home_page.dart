import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:go_router/go_router.dart';
import 'package:split_view/split_view.dart';

import '../data/recipe_repository.dart';
import '../data/settings.dart';
import '../login_info.dart';
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

  final _provider = VertexProvider(
    chatModel: FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
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

  final _repositoryFuture = RecipeRepository.forCurrentUser;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Vertex AI Cookbook'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout: ${LoginInfo.instance.displayName!}',
              onPressed: () async => await LoginInfo.instance.logout(),
            ),
            IconButton(
              onPressed: _onAdd,
              tooltip: 'Add Recipe',
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        drawer: Builder(builder: (context) {
          return _SettingsDrawer();
        }),
        body: FutureBuilderEx<RecipeRepository>(
          future: _repositoryFuture,
          builder: (context, repository) => _SideBySideOrTabBar(
            tabs: const [
              Tab(text: 'Recipes'),
              Tab(text: 'Chat'),
            ],
            children: [
              Column(
                children: [
                  SearchBox(onSearchChanged: _updateSearchText),
                  Expanded(
                    child: RecipeListView(
                      searchText: _searchText,
                      repository: repository!,
                    ),
                  ),
                ],
              ),
              LlmChatView(
                provider: _provider,
                responseBuilder: (context, response) => RecipeResponseView(
                  repository: repository,
                  response: response,
                ),
              ),
            ],
          ),
        ),
      );

  void _updateSearchText(String text) => setState(() => _searchText = text);

  void _onAdd() => context.goNamed(
        'edit',
        pathParameters: {'recipe': RecipeRepository.newRecipeID},
      );
}

class _SettingsDrawer extends StatelessWidget {
  final controller = TextEditingController(
    text: Settings.foodPreferences,
  );

  @override
  Widget build(BuildContext context) => Drawer(
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
}

class _SideBySideOrTabBar extends StatefulWidget {
  const _SideBySideOrTabBar({required this.tabs, required this.children});
  final List<Widget> tabs;
  final List<Widget> children;

  @override
  State<_SideBySideOrTabBar> createState() => _SideBySideOrTabBarState();
}

class _SideBySideOrTabBarState extends State<_SideBySideOrTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.of(context).size.width > 600
      ? SplitView(
          viewMode: SplitViewMode.Horizontal,
          gripColor: Colors.transparent,
          indicator: SplitIndicator(
            viewMode: SplitViewMode.Horizontal,
            color: Colors.grey,
          ),
          gripColorActive: Colors.transparent,
          activeIndicator: SplitIndicator(
            viewMode: SplitViewMode.Horizontal,
            isActive: true,
            color: Colors.black,
          ),
          children: widget.children,
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
