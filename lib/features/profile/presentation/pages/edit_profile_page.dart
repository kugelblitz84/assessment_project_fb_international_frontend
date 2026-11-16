import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Profile editing coming soon.'),
    ),
  );
}
