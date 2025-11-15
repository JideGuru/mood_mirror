import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';

import 'mood_mirror_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterGemma.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Mirror',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple.shade700),
        useMaterial3: true,
      ),
      home: const MoodMirrorPage(),
    );
  }
}
