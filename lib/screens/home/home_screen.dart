import 'package:flutter/material.dart';
import '../chat/user_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Whisper Chat')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserSearchScreen()),
            );
          },
          child: const Text('Start New Chat'),
        ),
      ),
    );
  }
}
