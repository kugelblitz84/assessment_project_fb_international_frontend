import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../widgets/async_state_view.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: SingleChildScrollView(
      child: StateMessage(
        title: 'Looks like a wrong turn',
        message: 'This AutoCare page does not exist.',
        icon: Icons.wrong_location_outlined,
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoutes.home),
          child: const Text('Go to Explore'),
        ),
      ),
    ),
  );
}
