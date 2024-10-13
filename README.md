The vertex_ai_cookbook project is a sample app written to showcase the power of Firebase Vertex AI. It's written in Flutter and leverages [the Flutter AI Toolkit](https://pub.dev/packages/flutter_ai_toolkit) as well as [Firebase Auth](https://pub.dev/packages/firebase_auth) and [Cloud Firestore](https://pub.dev/packages/cloud_firestore). At it's core, it relies on [Vertex AI for Firebase](https://pub.dev/packages/firebase_vertexai) for all of it's generative AI features.

# Features
Once you've logged in using your Google account, the cookbook app is split into two sections, one for recipes and one for a chat with the Vertex AI LLM. Those two sections are either side-by-side for desktop form factors:

TODO: intro-split.png

Or they're on individual tabs for mobile form factors:

TODO: intro-tabbed.png

When logging in as a new user, you'll get a set of default recipes for you to play around with. All of those recipes are stored in Cloud Firestore for you and you're free to explore them by simply expanding them to see their ingredients and instructions:

TODO: intro-expanded-recipe.png

These are your recipes, so feel free to add to them, edit them, delete them or search through them as you see fit:



add new recipes, edit existing recipes, delete recipes and even search recipes:

## Searching Recipes

TODO

## Generating Recipes

TODO

## User Preferences
TODO

## Multi-message Chat
TODO

## Multimodal Input
TODO

## Retrieval Augmented Generation (RAG)
TODO: RAG is certainly possible with the API provided by the Vertex AI SDK for Dart, but there's a bug blocking

## Non-chat Generative AI
TODO

## Multi-platform
TODO: iOS, Android, Web, macOS (not Windows or Linux)

# Getting Started

This sample relies on a Firebase project, which you then initialize in your app. You can do that with the steps described in [the Get started with the Gemini API using the Vertex AI in Firebase SDKs docs](https://firebase.google.com/docs/vertex-ai/get-started?platform=flutter).

After following those instructions, you're ready to use Firebase Vertex AI in your project. The sample already has the code in it to  initialize Firebase using your project:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

... // other imports

import 'firebase_options.dart'; // from `flutterfire config`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

... // app stuff here
```

This is the exact same way that you'd initialize Firebase for use in any Flutter project, so it should be familiar to existing FlutterFire users.

In addition to Firebase, this sample also uses [the Flutter AI Toolkit](https://github.com/csells/flutter_ai_toolkit), which provides the Firebase Vertex AI provider:

```dart
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ...

  final _provider = VertexProvider(
    chatModel: FirebaseVertexAI.instance.generativeModel(
      model: "gemini-1.5-flash",
      systemInstruction: Content.system(...),
    ),
    // ...
  );
}
```
# Cloud Firestore
TODO
https://firebase.google.com/docs/firestore/quickstart#dart_3
TODO: README/create-firestore-default-database.png

# Auth
TODO: https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/oauth.md#google-sign-in

as per: https://firebase.google.com/docs/rules/basics#cloud-firestore_2
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{documents=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId
    }
  }
}


# AppCheck
TODO: https://firebase.google.com/learn/pathways/firebase-app-check

