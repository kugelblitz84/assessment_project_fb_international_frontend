import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Lets a root overlay reach an already mounted shell without copying its state.
class NavigationShellScope extends InheritedWidget {
  const NavigationShellScope({
    super.key,
    required this.shellKey,
    required super.child,
  });
  final GlobalKey<StatefulNavigationShellState> shellKey;

  static StatefulNavigationShellState? maybeOf(BuildContext context) =>
      StatefulNavigationShell.maybeOf(context) ??
      context
          .dependOnInheritedWidgetOfExactType<NavigationShellScope>()
          ?.shellKey
          .currentState;

  @override
  bool updateShouldNotify(NavigationShellScope oldWidget) =>
      shellKey != oldWidget.shellKey;
}
