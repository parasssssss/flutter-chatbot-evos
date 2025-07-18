import 'package:flutter/material.dart';
import 'screens/chat_page.dart'; // Keep original import path

void main() {
  runApp(const AIChatApp());
}

class AIChatApp extends StatelessWidget {
  const AIChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zephyr AI Chat', // Improved app name
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark, // Dark theme
        ),
        useMaterial3: true,
      ),
      home: const AIChatPage(), // Keep using your existing ChatPage class
      debugShowCheckedModeBanner: false,
    );
  }
}
