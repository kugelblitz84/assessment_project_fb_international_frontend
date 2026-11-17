import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/session/application/current_user_provider.dart';
import '../../../../core/session/application/session_controller.dart';
import '../../../../core/widgets/navigation/auto_care_brand.dart';
import '../../../../routes/app_routes.dart';
import 'admin_widgets.dart';
import '../controller/admin_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child, required this.path});
  final Widget child;
  final String path;
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool loggingOut = false;
  static const destinations = [
    (AppRoutes.adminPath, 'Dashboard', Icons.dashboard_outlined),
    (AppRoutes.adminCategoriesPath, 'Categories', Icons.category_outlined),
    (AppRoutes.adminServicesPath, 'Services', Icons.car_repair_outlined),
    (AppRoutes.adminPackagesPath, 'Packages', Icons.inventory_2_outlined),
    (AppRoutes.adminOffersPath, 'Offers', Icons.local_offer_outlined),
    (
      AppRoutes.adminAppointmentsPath,
      'Appointments',
      Icons.calendar_month_outlined,
    ),
  ];
  Future<void> logout() async {
    if (loggingOut ||
        !await adminConfirm(
          context,
          'Log out?',
          'End this administrator session?',
        ) ||
        !mounted) {
      return;
    }
    setState(() => loggingOut = true);
    try {
      await ref.read(sessionProvider.notifier).logout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to clear your session. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  Widget navigation(bool drawer) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(padding: EdgeInsets.all(24), child: AutoCareBrand()),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text('ADMINISTRATION'),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final (path, label, icon) in destinations)
                ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  selected: path == AppRoutes.adminPath
                      ? widget.path == path
                      : widget.path.startsWith(path),
                  onTap: () {
                    if (drawer) Navigator.pop(context);
                    context.go(path);
                  },
                ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(loggingOut ? 'Logging out…' : 'Logout'),
          onTap: loggingOut ? null : logout,
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!ref.watch(adminAccessProvider)) return const SizedBox.shrink();
    final user = ref.watch(currentUserProvider);
    final title = destinations.reversed
        .firstWhere((d) => widget.path.startsWith(d.$1))
        .$2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          drawer: desktop ? null : Drawer(child: navigation(true)),
          appBar: AppBar(
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * .35,
                  ),
                  child: Text(
                    user?.name ?? 'Administrator',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (desktop) SizedBox(width: 240, child: navigation(false)),
              if (desktop) const VerticalDivider(width: 1),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}
