# vertex_ai_cookbook

Firebase Vertex AI Cookbook Sample written in Flutter

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
TODO

# AppCheck
TODO: https://firebase.google.com/learn/pathways/firebase-app-check

# Sample Features
- Chat: TODO
- Multimodal input: TODO
- User Prefefences: TODO
- RAG: TODO
- Non-chat Generative AI: TODO
