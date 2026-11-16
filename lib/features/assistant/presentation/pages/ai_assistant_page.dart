import 'package:flutter/material.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AutoCare AI assistant')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Text('AI service recommendations coming soon.'),
    ),
  );
}
