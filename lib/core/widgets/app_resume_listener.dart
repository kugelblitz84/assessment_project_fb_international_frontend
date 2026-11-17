import 'package:flutter/widgets.dart';

/// Observes resumes for a visible route, without retaining an old callback.
class AppResumeListener extends StatefulWidget {
  const AppResumeListener({
    super.key,
    required this.onResume,
    required this.child,
  });

  final VoidCallback onResume;
  final Widget child;

  @override
  State<AppResumeListener> createState() => _AppResumeListenerState();
}

class _AppResumeListenerState extends State<AppResumeListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true &&
        TickerMode.getValuesNotifier(context).value.enabled) {
      widget.onResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
